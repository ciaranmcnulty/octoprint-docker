default: run

dev:
	docker compose up --build

run:
	docker compose up -d

push:
	docker compose build --push

stop:
	docker compose down


.PHONY: *
