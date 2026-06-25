Welcome to the dbt 101 demo project. This project uses the [TPCH dataset](https://docs.snowflake.com/en/user-guide/sample-data-tpch.html) to show a clean, approachable dbt DAG with sources, staging models, intermediate models, marts, docs, and tests.

                        _              __                   
       ____ ___  ____ _(_)___     ____/ /__  ____ ___  ____ 
      / __ `__ \/ __ `/ / __ \   / __  / _ \/ __ `__ \/ __ \
     / / / / / / /_/ / / / / /  / /_/ /  __/ / / / / / /_/ /
    /_/ /_/ /_/\__,_/_/_/ /_/   \__,_/\___/_/ /_/ /_/\____/ 

## About the project
The project is intentionally small so it can stay organized and easy to adapt for customer-specific demos.

## Project shape
- `models/staging/tpch`: source-aligned cleanup models
- `models/marts/intermediate`: reusable business logic
- `models/marts/core`: customer, supplier, part, order, and order-item marts
- `models/marts/aggregates`: lightweight rollups for reporting examples
- `tests`: simple singular data tests
