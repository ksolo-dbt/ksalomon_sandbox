{{
    config(
        materialized = 'table',
        tags = ['finance']
    )
}}

with orders as (

    select
        order_key,
        order_date,
        order_time,
        customer_key,
        status_code,
        priority_code,
        clerk_name,
        ship_priority
    from {{ ref('stg_tpch_orders') }}

),

order_items as (

    select
        order_key,
        is_return,
        gross_item_sales_amount,
        item_discount_amount,
        item_tax_amount,
        net_item_sales_amount
    from {{ ref('order_items') }}

),

order_item_summary as (

    select
        order_key,
        sum(gross_item_sales_amount) as gross_item_sales_amount,
        sum(item_discount_amount) as item_discount_amount,
        sum(item_tax_amount) as item_tax_amount,
        sum(net_item_sales_amount) as net_item_sales_amount,
        count_if(is_return = true) as return_count
    from order_items
    group by 1

),

final as (

    select -- noqa: ST06
        orders.order_key,
        orders.order_date,
        orders.order_time,
        date_trunc('month', orders.order_time) as order_month,
        orders.customer_key,
        orders.status_code,
        orders.priority_code,
        orders.clerk_name,
        orders.ship_priority,
        1 as order_count,
        order_item_summary.return_count,
        order_item_summary.gross_item_sales_amount,
        order_item_summary.item_discount_amount,
        order_item_summary.item_tax_amount,
        order_item_summary.net_item_sales_amount
    from orders
        inner join order_item_summary
            on orders.order_key = order_item_summary.order_key

)

select * from final
