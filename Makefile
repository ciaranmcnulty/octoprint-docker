default: run

dev:
	docker compose up --build

prod:
	docker compose up --no-build --detach

push:
	docker compose build --push

stop:
	docker compose down


.PHONY: *
