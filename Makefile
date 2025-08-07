default: run

shell: run
	docker compose exec octoprint /bin/sh

logs: run
	docker compose logs -f octoprint

run:
	docker compose up -d

build-local: stop build-config
	docker buildx build --load .

build-push: stop build-config
	docker compose build --push .

stop:
	docker compose down

build-config:
	docker buildx bake --print

.PHONY: *
