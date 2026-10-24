# postgres-dbt-bootstrap

A simple Postgres + dbt setup I use to spin up PoCs. Clone it, run `make up`, and start building.

Postgres runs in Docker and dbt runs locally, so it feels like any other dbt project. It's deliberately minimal, so treat it as a starting point and add what you need.

## What's in it

- Postgres 18 in Docker, with data kept between restarts
- dbt Core 1.12, pinned with [uv](https://docs.astral.sh/uv/)
- `bronze` / `silver` / `gold` schemas
- A small script to load CSVs into Postgres
- A tiny example pipeline (seed → staging → snapshot → incremental fact) you can delete
- sqlfluff and a basic GitHub Actions workflow

## Getting started

You'll need [Docker](https://www.docker.com/products/docker-desktop/) and [uv](https://docs.astral.sh/uv/getting-started/installation/). `make` is optional (see [Without make](#without-make)).

```bash
make up            # start Postgres and install dbt
uv run dbt build   # build the example
```

To skip the `uv run` prefix, activate the environment with `source .venv/bin/activate` (Windows: `.venv\Scripts\activate`). VS Code does this for you.

Connect your SQL client of choice to `localhost:5432`, database `poc`, user `dbt`, password `dbt`.

## Day to day

| What | How |
|---|---|
| Start or pick up where you left off | `make up` |
| Run dbt | `dbt build -s my_model` (or any dbt command) |
| Load CSVs from `data/` | `make load` |
| Lint / fix SQL | `make lint` / `make fix` |
| Browse docs and lineage | `make docs` |
| Stop for the day (data is kept) | `make down` |
| Start from a clean database | `make reset` |

## Layers

| Schema | What goes in it |
|---|---|
| `bronze` | Raw data as it lands: seeds and loaded files |
| `silver` | Cleaned and typed: staging views and snapshots |
| `gold` | Tables people actually query |

Models land in exactly these schemas (not `public_silver`). Anything you don't configure goes to `public`.

## Loading files

Drop CSVs into `data/` and run `make load`. Each file becomes a table in `bronze`, named after the file (`Customer Extract.csv` becomes `bronze.customer_extract`). Every run reloads them from scratch.

Columns load as text on purpose. Do the typing in silver, where it's visible and testable. Then declare the tables in `models/bronze/_sources.yml` and use them with `{{ source('bronze', 'customer_extract') }}`.

`data/` is gitignored, so client files stay on your machine.

## Starting a real PoC

```bash
make clean-examples   # remove the example models, seeds and snapshot
make reset            # clear their tables
```

Commit the `uv.lock` that gets created on your first `make up`, so everyone gets the same versions.

## Settings

Defaults work as is. To change them, copy `.env.example` to `.env`. Docker, dbt and the loader all read it.

- **Port 5432 already taken?** Set `POSTGRES_PORT=5433`, or `make down` in the other project first.
- **Using an existing Postgres instead?** Put its details in `.env`, skip Docker and run `uv sync`. Everything else works the same.

## CI

On every push to `main` and every pull request, GitHub Actions lints the SQL, starts Postgres and runs `dbt build`. Models built on files in `data/` are only compiled, since those files never get committed. Delete `.github/workflows/ci.yml` if you don't need it.

## A few notes

- **Keep model names lowercase.** dbt quotes names on Postgres, so `fct_Orders` becomes a table you can only query as `"fct_Orders"`.
- **Incremental models** keep old logic for rows already loaded. Run `dbt build --full-refresh -s my_model` after changing them.
- **Want to see the snapshot work?** Change account `A003` to `closed` in `seeds/example/example_accounts.csv`, bump its `updated_at`, run `dbt build`, then look at `silver.snap_example_accounts`.

## Without make

| make | Run this instead |
|---|---|
| `make up` | `docker compose up -d --wait` then `uv sync` |
| `make down` | `docker compose down` |
| `make reset` | `docker compose down -v` then `docker compose up -d --wait` |
| `make load` | `uv run python scripts/load.py` |
| `make lint` | `uv run sqlfluff lint models` |
| `make docs` | `uv run dbt docs generate` then `uv run dbt docs serve --port 8080` |
