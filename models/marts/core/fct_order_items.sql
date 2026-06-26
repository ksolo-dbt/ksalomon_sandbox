{{
    config(
        materialized = 'table',
        tags = ['finance']
    )
}}

with order_item as (

    select * from {{ ref('order_items') }}

),

part_supplier as (

    select * from {{ ref('part_suppliers') }}

),

final as (
    select
        order_item.order_item_key,
        order_item.order_key,
        order_item.order_date,
        order_item.customer_key,
        order_item.part_key,
        order_item.supplier_key,
        order_item.order_item_status_code,
        order_item.is_returned,
        order_item.line_number,
        order_item.ship_date,
        order_item.commit_date,
        order_item.receipt_date,
        order_item.ship_mode,
        part_supplier.cost as supplier_cost,
        {# ps.retail_price, #}
        order_item.base_price,
        order_item.discount_percentage,
        order_item.discounted_price,
        order_item.tax_rate,
        part_supplier.nation_key,
        1 as order_item_count,
        order_item.quantity,
        order_item.gross_item_sales_amount,
        order_item.discounted_item_sales_amount,
        order_item.item_discount_amount,
        order_item.item_tax_amount,
        order_item.net_item_sales_amount

    from
        order_item
        inner join part_supplier
            on
                order_item.part_key = part_supplier.part_key
                and order_item.supplier_key = part_supplier.supplier_key

)

select
    order_item_key,
    order_key,
    order_date,
    customer_key,
    part_key,
    supplier_key,
    order_item_status_code,
    is_returned,
    line_number,
    ship_date,
    commit_date,
    receipt_date,
    ship_mode,
    supplier_cost,
    base_price,
    discount_percentage,
    discounted_price,
    tax_rate,
    nation_key,
    order_item_count,
    quantity,
    gross_item_sales_amount,
    discounted_item_sales_amount,
    item_discount_amount,
    item_tax_amount,
    net_item_sales_amount
from
    final
order by
    3
