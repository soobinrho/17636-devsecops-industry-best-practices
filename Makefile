#!make
include .env
SONARQUBE_ADMIN_PASS_URL_ENCODED := $(shell echo -n "${SONARQUBE_ADMIN_PASS}" | jq -sRr @uri)
SONARQUBE_ADMIN_USER_URL_ENCODED := $(shell echo -n "${SONARQUBE_ADMIN_USER}" | jq -sRr @uri)

start-build-pipeline:	clean \
						check-if-env-file-ready \
						docker-compose-up-sonarqube \
						configure-sonarqube \
						create-sonarqube-project \
						generate-sonarqube-token \
						provision-jenkins-ssh-agent \
						setup-env-file-jenkins \
						setup-env-file-jenkins-ssh-agent \
						setup-env-file-grafana \
						setup-env-file-petclinic \
						docker-compose-up

check-if-env-file-ready:
	if [ ! -f ./.env ]; then \
	  echo '[ERROR] .env file does not exist. Please cp ./.env.example .env and populate the variables.'; \
		exit 1; \
	fi

docker-compose-up-sonarqube:
	cd server-build && \
		docker compose up 17636-sonarqube --wait -d

configure-sonarqube:
	# I got these API endpoint with Chrome Developer Tool (F12) - Network -
	# filter by Fetch/XHR - Headers and Payload and the API documentation:
	#   http://localhost:9000/web_api/api/user_tokens
	echo '[INFO] Configuring SonarQube...'
	curl -X POST -u admin:admin --silent \
		"http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=${SONARQUBE_ADMIN_PASS_URL_ENCODED}"
	curl --fail -X POST -u admin:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/users/create?login=${SONARQUBE_ADMIN_USER_URL_ENCODED}&name=${SONARQUBE_ADMIN_USER_URL_ENCODED}&email=${SONARQUBE_ADMIN_USER_URL_ENCODED}%40localhost&password=${SONARQUBE_ADMIN_PASS_URL_ENCODED}" \
		  > /dev/null && \
				echo "[INFO] Successfully created SonarQube user (Username: ${SONARQUBE_ADMIN_USER})." || \
				echo "[INFO] Successfully configured SonarQube user (Username: ${SONARQUBE_ADMIN_USER})."
	curl -X POST -u admin:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/permissions/add_user?login=${SONARQUBE_ADMIN_USER_URL_ENCODED}&permission=admin"
	curl -X POST -u admin:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/permissions/add_user?login=${SONARQUBE_ADMIN_USER_URL_ENCODED}&permission=gateadmin"
	curl -X POST -u admin:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/permissions/add_user?login=${SONARQUBE_ADMIN_USER_URL_ENCODED}&permission=profileadmin"
	curl -X POST -u admin:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/permissions/add_user?login=${SONARQUBE_ADMIN_USER_URL_ENCODED}&permission=scan"
	curl -X POST -u admin:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/permissions/add_user?login=${SONARQUBE_ADMIN_USER_URL_ENCODED}&permission=provisioning"
	# Add the user to the admins group.
	curl -u ${SONARQUBE_ADMIN_USER}:${SONARQUBE_ADMIN_PASS} --silent http://localhost:9000/api/v2/authorizations/groups?q=sonar-administrators | jq --raw-output '.groups.[0].id' \
		> ./server-build/17636-sonarqube-group-id.temp
	curl -u ${SONARQUBE_ADMIN_USER}:${SONARQUBE_ADMIN_PASS} --silent http://localhost:9000/api/users/current | jq --raw-output '.id' \
		> ./server-build/17636-sonarqube-user-id.temp
	curl --fail -X POST -u ${SONARQUBE_ADMIN_USER}:${SONARQUBE_ADMIN_PASS} --silent \
		-H "Content-Type: application/json" \
		--data "{\"groupId\":\"$$(cat ./server-build/17636-sonarqube-group-id.temp)\", \"userId\":\"$$(cat ./server-build/17636-sonarqube-user-id.temp)\"}" \
		"http://localhost:9000/api/v2/authorizations/group-memberships" \
			> /dev/null && \
				echo "[INFO] Successfully added to the admins group (Username: ${SONARQUBE_ADMIN_USER})." || \
				echo "[INFO] Successfully configured the admins group membership (Username: ${SONARQUBE_ADMIN_USER})."
	rm -f ./server-build/17636-sonarqube-group-id.temp
	rm -f ./server-build/17636-sonarqube-user-id.temp

create-sonarqube-project:
	curl --fail -X POST -u ${SONARQUBE_ADMIN_USER}:${SONARQUBE_ADMIN_PASS} --silent \
    "http://localhost:9000/api/projects/create?project=petclinic&name=petclinic" \
		  > /dev/null && \
				echo "[INFO] Successfully created SonarQube project (Project Name: petclinic)." || \
				echo "[INFO] Successfully configured SonarQube project (Project Name: petclinic)."

generate-sonarqube-token:
	if [ ! -f ./server-build/17636-sonarqube-token.key ]; then \
		echo '[INFO] Generating a SonarQube token...'; \
		curl -X POST -u ${SONARQUBE_ADMIN_USER}:${SONARQUBE_ADMIN_PASS} --silent \
			"http://localhost:9000/api/user_tokens/generate?name=sonarqube-token&projectKey=petclinic&type=PROJECT_ANALYSIS_TOKEN" \
			--output ./server-build/17636-sonarqube-token.key; \
		cat ./server-build/17636-sonarqube-token.key | jq --raw-output '.token' \
			> ./server-build/17636-sonarqube-token.key.buffer; \
		mv ./server-build/17636-sonarqube-token.key.buffer ./server-build/17636-sonarqube-token.key; \
	fi

provision-jenkins-ssh-agent:
	if [ ! -f ./server-build/17636-jenkins-ssh-agent.key ]; then \
		echo '[INFO] Provisioning a new ssh key for Jenkins SSH agent...'; \
		yes | ssh-keygen -q -N "" -f ./server-build/17636-jenkins-ssh-agent.key; \
	fi

setup-env-file-jenkins:
	echo "# Do not manually modify this file. This file is generated by ../Makefile" \
		> ./server-build/.env.jenkins
	grep '^JENKINS_URL_AND_PORT=' ./.env \
		>> ./server-build/.env.jenkins
	grep '^JENKINS_ADMIN_USER=' ./.env \
		>> ./server-build/.env.jenkins
	grep '^JENKINS_ADMIN_PASS=' ./.env \
		>> ./server-build/.env.jenkins
	echo "JENKINS_AGENT_SSH_PRIVATE_KEY=\"$$(cat ./server-build/17636-jenkins-ssh-agent.key)\"" \
		>> ./server-build/.env.jenkins
	echo "SONARQUBE_TOKEN=$$(cat ./server-build/17636-sonarqube-token.key)" \
		>> ./server-build/.env.jenkins
	echo "[INFO] Successfully completed Jenkins configuration (Username: ${JENKINS_ADMIN_USER})."

setup-env-file-jenkins-ssh-agent:
	echo "# Do not manually modify this file. This file is generated by ../Makefile" \
		> ./server-build/.env.jenkins-ssh-agent
	echo "JENKINS_AGENT_SSH_PUBKEY=$$(cat ./server-build/17636-jenkins-ssh-agent.key.pub)" \
		>> ./server-build/.env.jenkins-ssh-agent

setup-env-file-grafana:
	echo "# Do not manually modify this file. This file is generated by ../Makefile" \
		> ./server-build/.env.grafana
	grep '^GF_SECURITY_ADMIN_PASSWORD=' ./.env \
		>> ./server-build/.env.grafana
	grep '^GF_SECURITY_ADMIN_USER=' ./.env \
		>> ./server-build/.env.grafana
	grep '^GF_USERS_ALLOW_SIGN_UP=' ./.env \
		>> ./server-build/.env.grafana

setup-env-file-petclinic:
	echo "# Do not manually modify this file. This file is generated by ../Makefile" \
		> ./server-build/.env.petclinic
	grep '^POSTGRES_PASSWORD=' ./.env \
		>> ./server-build/.env.petclinic
	grep '^POSTGRES_PASS=' ./.env \
		>> ./server-build/.env.petclinic

docker-compose-up:
	cd server-build && \
		docker compose up --build --force-recreate -d \
			17636-jenkins \
			17636-jenkins-ssh-agent \
			17636-zap \
			17636-prometheus-node-exporter \
			17636-prometheus \
			17636-grafana

logs:
	cd server-build && \
	  docker compose logs -f

reset:	clean clean-remove-volumes start-build-pipeline

clean:
	cd server-build && \
	  docker compose down --remove-orphans || true

clean-remove-volumes:
	docker volume ls -q --filter 'name=17636-*' | xargs docker volume rm
	rm -f ./server-build/.env.jenkins
	rm -f ./server-build/.env.jenkins-ssh-agent
	rm -f ./server-build/.env.grafana
	rm -f ./server-build/.env.petclinic
	rm -f ./server-build/17636-jenkins-ssh-agent.key
	rm -f ./server-build/17636-jenkins-ssh-agent.key.pub
	rm -f ./server-build/17636-sonarqube-token.key

clean-remove-images:
	docker images -aq --filter 'reference=soobinrho/17636-*' \
		| xargs docker image rm --force

test-sh-in-sonarqube:
	cd server-build && \
		docker compose exec 17636-sonarqube bash

test-sh-in-jenkins-ssh-agent:
	cd server-build && \
		docker compose exec 17636-jenkins-ssh-agent bash

test-sh-in-jenkins:
	cd server-build && \
		docker compose exec 17636-jenkins bash

test-sh-in-zap:
	cd server-build && \
		docker compose exec 17636-zap bash

test-sh-in-prometheus-node-exporter:
	cd server-build && \
		docker compose exec 17636-prometheus-node-exporter sh

test-sh-in-postgres:
	cd server-build && \
		docker compose exec 17636-postgres bash

.SILENT: start-build-pipeline \
	check-if-env-file-ready \
	docker-compose-up-sonarqube \
	configure-sonarqube \
	create-sonarqube-project \
	generate-sonarqube-token \
	provision-jenkins-ssh-agent \
	setup-env-file-jenkins \
	setup-env-file-jenkins-ssh-agent \
	setup-env-file-grafana \
	setup-env-file-petclinic \
	docker-compose-up \
	logs \
	clean \
	clean-remove-volumes \
	clean-remove-images \
	test-sh-in-sonarqube \
	test-sh-in-jenkins-ssh-agent \
	test-sh-in-jenkins \
	test-sh-in-zap \
	test-sh-in-prometheus-node-exporter \
	test-sh-in-postgres

