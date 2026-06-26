{{
    config(
        enabled=true,
        severity='error',
        tags = ['finance']
    )
}}

with orders as (
    select
        order_key,
        total_price
    from {{ ref('stg_tpch_orders') }}
)

select
    order_key,
    total_price
from orders
where total_price < 0
