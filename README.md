# Kyle Salomon's dbt Demo Project

This repo is my personal dbt demo project, sandbox, and customer-facing playground as a Solutions Architect. It gives me a controlled space to show the art of the possible with dbt while keeping the examples, data, modeling choices, and demo narrative fully in my hands.

The project is intentionally approachable: small enough to explain live, but realistic enough to demonstrate how analytics engineering practices scale from raw sources to tested, documented marts.

                        _              __                   
       ____ ___  ____ _(_)___     ____/ /__  ____ ___  ____ 
      / __ `__ \/ __ `/ / __ \   / __  / _ \/ __ `__ \/ __ \
     / / / / / / /_/ / / / / /  / /_/ /  __/ / / / / / /_/ /
    /_/ /_/ /_/\__,_/_/_/ /_/   \__,_/\___/_/ /_/ /_/\____/ 

## What this project is for

- Demonstrating dbt concepts in customer conversations and workshops
- Prototyping modeling patterns before applying them in customer-specific contexts
- Showing how clean project structure, documentation, tests, and linting work together
- Maintaining a repeatable sandbox where examples can evolve without depending on external customer environments

## What it demonstrates

- Source-aligned staging models over the TPCH sample dataset
- Reusable intermediate models for business logic and grain management
- Core marts for customers, orders, order items, parts, and suppliers
- Aggregate models for reporting and dashboard-style examples
- Utility models such as daily and hourly time spines
- Singular tests, schema tests, docs, and macros that support maintainable demos

## Project shape

- `models/staging/tpch`: source cleanup and standardization for TPCH data
- `models/marts/intermediate`: reusable business logic between staging and marts
- `models/marts/core`: primary dimensional and fact-style marts
- `models/marts/aggregates`: lightweight rollups for reporting examples
- `models/utils`: reusable helper models such as time spines
- `macros`: project-specific helper macros
- `tests`: singular data tests for demoable data quality checks
- `docs/runbooks`: notes and runbooks for project-specific workflows

## Demo philosophy

This project is not meant to be a generic starter template. It is a curated environment for telling practical dbt stories: how we move from raw data to trusted marts, how we keep transformations understandable, and how teams can build confidence through tests, docs, and consistent conventions.

The goal is to make customer conversations tangible. Instead of describing best practices in the abstract, this repo provides concrete examples that can be inspected, modified, and extended live.

## Common dbt commands

```bash
dbt parse
dbt build
dbt build --select models/staging/tpch+
dbt test
```

## Local lint and check workflow

This project keeps dbt execution checks, SQL style checks, and dbt Studio/Fusion
linting as separate steps so local development can stay fast while still
matching Studio before opening or updating a PR.

```bash
make lint-sql
make lint-dbt
make compile
make check
```

- `make lint-sql` runs SQLFluff through `uvx` with the Jinja templater and
  templating tolerance so style checks do not need a warehouse connection or
  full dbt project compilation.
- `make lint-sql SQLFLUFF_TEMPLATER=dbt` runs SQLFluff with the dbt templater
  when the local dbt environment can parse the full project.
- `make lint-dbt` runs `dbt parse`, which catches dbt Core parsing and project
  configuration issues.
- `make compile` runs `dbt compile`; pass `DBT_SELECT` for scoped compiles, such
  as `make compile DBT_SELECT=stg_tpch_orders`.
- `make check` runs SQLFluff, `dbt parse`, and `dbt compile` together.
- `make lint-studio` is reserved for the local dbt Studio/Fusion lint command
  once installed. Set it with `STUDIO_LINT`, for example
  `make lint-studio STUDIO_LINT='<studio lint command>'`.

When dbt Studio lists Problems such as `dbt0175 / JinjaPadding`, copy the full
Problems list into the PR or local notes before fixing. That gives a clean
baseline for confirming whether local SQLFluff, dbt Core, or Studio/Fusion lint
is responsible for each issue.

## Notes

This is an evolving sandbox. Some examples are intentionally lightweight so they can be adapted quickly for demos, workshops, and customer-specific conversations.
