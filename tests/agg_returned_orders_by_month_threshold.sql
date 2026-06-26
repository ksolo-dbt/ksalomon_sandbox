{# Changed from 'error' to 'warn' to use as a demo for testing capabilities
   This test checks if return rate > 50% in the most recent month
   When it fails (returns rows), it indicates high return rates
   Use this to demonstrate: test failures, investigating data quality issues, and adjusting thresholds #}
{{
    config(
        enabled=true,
        severity='warn',
    )
}}

with agg_returned_orders_by_month as (
    select
        order_month,
        returned_orders,
        return_rate,
        row_count
    from {{ ref('agg_returned_orders_by_month') }}
)

select
    returned_orders_by_month.order_month,
<<<<<<< HEAD
    returned_orders_by_month.returned_orders,
    returned_orders_by_month.return_rate,
    returned_orders_by_month.row_count
=======
    returned_orders_by_month.return_rate
>>>>>>> 37ea214fd0627a5514367bb2b2f666b3f9e77135
from agg_returned_orders_by_month as returned_orders_by_month
where
    returned_orders_by_month.order_month = (
        select max(latest_month.order_month) as max_order_month
        from agg_returned_orders_by_month as latest_month
    )
    and returned_orders_by_month.return_rate > 0.50
