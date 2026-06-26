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
<<<<<<< HEAD
    order_key,
    total_price
=======
    orders.order_key,
    orders.total_price
>>>>>>> 37ea214fd0627a5514367bb2b2f666b3f9e77135
from orders
where orders.total_price < 0
