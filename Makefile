#!make

GIT_HASH := $(shell git rev-parse --short HEAD)

all:	build deploy

build:
	cd spring-petclinic && \
		./mvnw spring-boot:build-image \
			-Dspring-boot.build-image.imageName="soobinrho/17636-pet-clinic:${GIT_HASH}" \
			-Dspring-boot.run.profiles=postgres
	docker tag "soobinrho/17636-pet-clinic:${GIT_HASH}" 'soobinrho/17636-pet-clinic:latest'

deploy:
	echo deploying placeholder

cleanup-remove-containers:
	docker ps -aq --filter 'name=soobinrho/17636-' \
		| sort | uniq -u | xargs docker stop | xargs docker rm --force

cleanup-remove-images:
	docker images -aq --filter 'reference=soobinrho/17636-*' \
		| xargs docker image rm --force

.SILENT: build deploy cleanup
