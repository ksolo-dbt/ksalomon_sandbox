with fct_order_items as (
    select * from {{ ref('fct_order_items') }}
),

final as (
    select
        date_trunc('month', fct_order_items.order_date) as order_month,
        count_if(fct_order_items.is_return) as returned_orders,
        1.0 * count_if(fct_order_items.is_return) / nullif(
            count(fct_order_items.order_item_key),
            0
        ) as return_rate,
        count(*) as row_count
    from fct_order_items
    group by 1
    order by 1 desc
)

select * from final
