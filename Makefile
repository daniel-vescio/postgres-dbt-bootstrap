# Shortcuts only. Run dbt directly: `dbt build -s my_model`.
# No make (e.g. Windows)? Copy the commands under each target.

.DEFAULT_GOAL := help
.PHONY: help up down reset load lint fix docs clean-examples

help: ## Show commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start Postgres and install dbt
	docker compose up -d --wait
	uv sync

down: ## Stop Postgres (keeps your data)
	docker compose down

reset: ## Wipe the database and start fresh
	docker compose down -v
	docker compose up -d --wait

load: ## Load CSVs from data/ into bronze
	uv run python scripts/load.py

lint: ## Check SQL style
	uv run sqlfluff lint models

fix: ## Fix SQL style
	uv run sqlfluff fix models

docs: ## dbt docs at http://localhost:8080
	uv run dbt docs generate
	uv run dbt docs serve --port 8080

clean-examples: ## Delete the example models, seeds and snapshot
	rm -rf seeds/example snapshots/example models/silver/example models/gold/example
	@echo "Done. Run 'make reset' to clear their tables too."
