run: build start

build:
	docker build . -t keycloak:themes

start:
	docker run -p 8080:8080 -v ./theme/:/opt/keycloak/themes/:ro keycloak:themes