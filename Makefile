default: run

shell: run
	docker compose exec octoprint /bin/sh

logs: run
	docker compose logs -f octoprint

run: build
	docker compose up -d

build: stop build-config
	docker compose build octoprint

stop:
	docker compose down

build-config:
	docker buildx bake --print

.PHONY: *
