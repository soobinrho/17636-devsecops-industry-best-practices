#!make

start-build-pipeline:
	cd server-build && docker compose down --remove-orphans || 1
	cd server-build && docker compose up -d

cleanup-remove-containers:
	docker ps -aq --filter 'name=soobinrho/17636-' \
		| sort | uniq -u | xargs docker stop | xargs docker rm --force

cleanup-remove-images:
	docker images -aq --filter 'reference=soobinrho/17636-*' \
		| xargs docker image rm --force

.SILENT: start-build-pipeline
