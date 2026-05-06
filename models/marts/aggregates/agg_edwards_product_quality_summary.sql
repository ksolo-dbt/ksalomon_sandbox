
{{
    config(
        materialized = 'table'
    )
}}

with batch_stats as (

    select
        products.business_unit,
        products.device_family,
        batches.product_id,
        products.product_name,
        date_trunc('month', batches.production_date)  as month,
        sum(batches.units_produced)                   as total_units_produced,
        sum(batches.units_reworked)                   as total_units_reworked,
        sum(batches.units_scrapped)                   as total_units_scrapped
    from {{ ref('stg_edwards_lifesciences_production_batches') }} as batches
    left join {{ ref('stg_edwards_lifesciences_product_master') }} as products
        on batches.product_id = products.product_id
    group by
        products.business_unit,
        products.device_family,
        batches.product_id,
        products.product_name,
        date_trunc('month', batches.production_date)

),

event_stats as (

    select
        business_unit,
        device_family,
        product_id,
        date_trunc('month', production_date)            as month,
        count(*)                                        as total_quality_events,
        count_if(event_type = 'Field Complaint')        as total_field_complaints,
        count_if(severity = 'CRITICAL')                 as total_critical_events
    from {{ ref('int_edwards_batch_events') }}
    group by
        business_unit,
        device_family,
        product_id,
        date_trunc('month', production_date)

),

shipment_stats as (

    select
        business_unit,
        device_family,
        product_id,
        date_trunc('month', shipment_date) as month,
        sum(units_shipped)                 as total_units_shipped
    from {{ ref('int_edwards_shipments') }}
    group by
        business_unit,
        device_family,
        product_id,
        date_trunc('month', shipment_date)

),

final as (

    select
        batch_stats.business_unit,
        batch_stats.device_family,
        batch_stats.product_id,
        batch_stats.product_name,
        batch_stats.month,
        batch_stats.total_units_produced,
        batch_stats.total_units_reworked,
        batch_stats.total_units_scrapped,
        coalesce(event_stats.total_quality_events, 0)   as total_quality_events,
        coalesce(event_stats.total_field_complaints, 0) as total_field_complaints,
        coalesce(event_stats.total_critical_events, 0)  as total_critical_events,
        coalesce(shipment_stats.total_units_shipped, 0) as total_units_shipped
    from batch_stats
    left join event_stats
        on  batch_stats.business_unit = event_stats.business_unit
        and batch_stats.device_family = event_stats.device_family
        and batch_stats.product_id    = event_stats.product_id
        and batch_stats.month         = event_stats.month
    left join shipment_stats
        on  batch_stats.business_unit = shipment_stats.business_unit
        and batch_stats.device_family = shipment_stats.device_family
        and batch_stats.product_id    = shipment_stats.product_id
        and batch_stats.month         = shipment_stats.month

)

select * from final
