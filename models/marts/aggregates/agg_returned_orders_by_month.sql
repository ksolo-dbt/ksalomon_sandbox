with fct_order_items as (
    select * from {{ ref('fct_order_items') }}
),

final as (
    select
<<<<<<< HEAD
        date_trunc(month, fct_order_items.order_date) as order_month,
        count(
            case
                when fct_order_items.is_returned
                    then fct_order_items.order_item_key
            end
        )
            as returned_orders,
        1.0 * returned_orders / nullif(
=======
        date_trunc('month', fct_order_items.order_date) as order_month,
        count_if(fct_order_items.is_return) as returned_orders,
        1.0 * count_if(fct_order_items.is_return) / nullif(
>>>>>>> 37ea214fd0627a5514367bb2b2f666b3f9e77135
            count(fct_order_items.order_item_key),
            0
        ) as return_rate,
        count(*) as row_count
    from fct_order_items
    group by 1
    order by 1 desc
)

select
    order_month,
    returned_orders,
    return_rate,
    row_count
from final
