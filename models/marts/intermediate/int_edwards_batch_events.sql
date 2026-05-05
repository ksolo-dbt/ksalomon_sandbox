
with batches as (

    select * from {{ ref('stg_edwards_lifesciences_production_batches') }}

),

products as (

    select * from {{ ref('stg_edwards_lifesciences_product_master') }}

),

quality_events as (

    select * from {{ ref('stg_edwards_lifesciences_quality_events') }}

),

final as (

    select
        batches.batch_id,
        batches.product_id,
        products.product_name,
        products.device_family,
        batches.business_unit,
        batches.manufacturing_site_id,
        batches.production_date,
        batches.units_produced,
        batches.units_reworked,
        batches.units_scrapped,
        quality_events.event_id,
        quality_events.event_date,
        quality_events.event_type,
        quality_events.severity,
        quality_events.detected_at,
        quality_events.region as event_region
    from batches
    left join products
        on batches.product_id = products.product_id
    left join quality_events
        on batches.batch_id = quality_events.batch_id

)

select * from final
