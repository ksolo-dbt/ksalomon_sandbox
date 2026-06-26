{{
    config(
        enabled=true,
        severity='error',
        tags = ['finance']
    )
}}

with orders as (select * from {{ ref('stg_tpch_orders') }})

select
    orders.order_key,
    orders.total_price
from orders
where orders.total_price < 0
