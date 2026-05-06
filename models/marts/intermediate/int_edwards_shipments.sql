
with shipments as (

    select * from {{ ref('stg_edwards_lifesciences_shipments') }}

),

hospitals as (

    select * from {{ ref('stg_edwards_lifesciences_hospital_accounts') }}

),

products as (

    select * from {{ ref('stg_edwards_lifesciences_product_master') }}

),

final as (

    select
        shipments.shipment_id,
        shipments.shipment_date,
        shipments.units_shipped,
        shipments.region          as shipment_region,
        hospitals.hospital_id,
        hospitals.hospital_name,
        hospitals.country,
        hospitals.region          as hospital_region,
        hospitals.is_teaching_hospital,
        hospitals.primary_specialty,
        products.product_id,
        products.product_name,
        products.business_unit,
        products.device_family
    from shipments
    left join hospitals
        on shipments.hospital_id = hospitals.hospital_id
    left join products
        on shipments.product_id = products.product_id

)

select * from final
