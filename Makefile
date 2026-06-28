include .env
export

export PROJECT_ROOT=$(shell pwd)

tools:
	@go install github.com/bufbuild/buf/cmd/buf@latest
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

proto-lint:
	@buf lint api/proto

proto:
	@buf generate

proto-breaking:
	@buf breaking api/proto --against '.git#branch=main,subdir=api/proto'

env-up:
	@docker compose up -d postgres redis kafka

env-down:
	@docker compose down

env-cleanup:
	@docker compose down -v

env-logs:
	@docker compose logs -f postgres redis kafka

migrate-create:
	@if [ -z "$(seq)" ]; then \
		echo "Error: Environment variable seq is not set. Example: make migrate-create seq=1"; \
		exit 1; \
	fi; \
	docker compose run --rm --user "$(shell id -u):$(shell id -g)" migrate create \
		-ext sql \
		-dir /migrations \
		-seq "$(seq)"

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