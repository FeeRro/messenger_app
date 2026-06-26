include .env
export

export PROJECT_ROOT=${shell pwd}

env-up:
	@docker compose up -d postgres

env-down:
	@docker compose down

env-cleanup:
	@docker compose down -v

env-logs:
	@docker compose logs -f postgres

migrate-create:
	if [ -z "$(seq)]; then \
		echo: "Error: Environment variable SEQ is not set. Example: make migrate-create seq=1"; \
		exit 1; \
	fi; \
	docer compose run --rm migrate create \
		-ext sql \
		-dir /migrations \
		-seq "$(SEQ)"

migrate-up:
	@make migrate-action action=up

migrate-down:
	@make migrate-action action=down

migrate-action:
	@if [ -z "$(action)" ]; then \
		echo "Error: Environment variable action is not set. Example: make migrate-action action=up"; \
		exit 1; \
	fi; \
	docker compose run --rm todolist-postgres-migrate \
		-path /migrations \
		-database postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@todolist-postgres:5432/${POSTGRES_DB}?sslmode=disable \
		"$(action)"