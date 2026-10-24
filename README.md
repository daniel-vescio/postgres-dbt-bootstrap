# postgres-dbt-bootstrap

A simple Postgres + dbt starter for PoCs. Clone it, run the setup commands below, and start building models.

Postgres runs in Docker and dbt runs locally, so it works like any other dbt project. It's deliberately minimal. Add what you need as you go.

**This is set up for Windows.** All commands below are for PowerShell.

## What's included

- Postgres 18 in Docker, with data kept between restarts
- dbt Core 1.12, with versions pinned by [uv](https://docs.astral.sh/uv/)
- `bronze` / `silver` / `gold` schemas
- A script to load CSVs into Postgres
- A small example pipeline (seed → staging → snapshot → incremental fact) you can delete
- sqlfluff for linting
- A GitHub Actions workflow that lints and runs `dbt build` (delete `.github/workflows/ci.yml` if you don't need it)

## Getting started

You'll need [Docker Desktop](https://www.docker.com/products/docker-desktop/) and [uv](https://docs.astral.sh/uv/getting-started/installation/).

Start Docker Desktop before running anything. If you get `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified`, Docker Desktop isn't running.

```powershell
docker compose up -d --wait   # start Postgres
uv sync                       # install dbt
uv run dbt debug              # check dbt can connect
uv run dbt build              # build the example
```

To skip the `uv run` prefix, activate the environment with `.venv\Scripts\activate` and run `dbt build` directly. VS Code activates it for you. If PowerShell says running scripts is disabled, run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.

To connect a SQL client, use `localhost:5432`, database `poc`, user `dbt`, password `dbt`. These are the defaults (see [Settings](#settings)).

## Day to day

| What | Command |
|---|---|
| Start Postgres | `docker compose up -d --wait` |
| Run dbt | `uv run dbt build -s my_model` (or any dbt command) |
| Load CSVs from `data/` | `uv run python scripts/load.py` |
| Lint SQL | `uv run sqlfluff lint models` |
| Fix SQL | `uv run sqlfluff fix models` |
| View docs and lineage | `uv run dbt docs generate; uv run dbt docs serve --port 8080` |
| Stop Postgres (data is kept) | `docker compose down` |
| Wipe the database and start fresh | `docker compose down -v; docker compose up -d --wait` |

## Layers

| Schema | What goes in it |
|---|---|
| `bronze` | Raw data: seeds and loaded files |
| `silver` | Cleaned and typed: staging views and snapshots |
| `gold` | Tables people query |

Models build into exactly these schemas (not `public_silver`). Anything without a layer goes to `public`.

## Loading files

Put CSVs in `data/` and run `uv run python scripts/load.py`. Each file becomes a table in `bronze`, named after the file (`Customer Extract.csv` becomes `bronze.customer_extract`). Every run reloads them from scratch.

All columns load as text. Do the typing in silver, where it's visible and testable. Then declare the tables in `models/bronze/_sources.yml` and reference them with `{{ source('bronze', 'customer_extract') }}`.

`data/` is gitignored, so client files aren't committed.

## Starting a real PoC

Remove the example models, seeds and snapshot, then wipe the database to drop their tables:

```powershell
Remove-Item -Recurse -Force seeds/example, snapshots/example, models/silver/example, models/gold/example
docker compose down -v; docker compose up -d --wait
```

`uv.lock` pins the exact package versions. Keep it committed so everyone on the project gets the same versions. Run `uv lock --upgrade` to update them.

## Settings

The defaults work without any changes. To change them, copy `.env.example` to `.env` (`Copy-Item .env.example .env`) and edit it. Docker, dbt and the CSV loader all read `.env`.

- **Changing the user, password or database name:** Postgres only applies these when the database is first created. After changing them, run `docker compose down -v; docker compose up -d --wait`. This deletes all data.
- **Changing the dbt version:** update the `dbt-core` / `dbt-postgres` versions in `pyproject.toml`, then run `uv sync`.
- **Port 5432 already in use:** set `POSTGRES_PORT=5433`, or stop the other project with `docker compose down`.
- **Using an existing Postgres server:** put its details in `.env`, skip Docker, and run `uv sync`. Everything else works the same.
