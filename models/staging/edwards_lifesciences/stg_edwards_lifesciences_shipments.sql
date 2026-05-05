
with source as (

    select * from {{ source('edwards_lifesciences_raw', 'raw_shipments') }}

),

final as (

    select
        trim(shipment_id)          as shipment_id,
        trim(hospital_id)          as hospital_id,
        trim(product_id)           as product_id,
        trim(batch_id)             as batch_id,
        to_date(shipment_date)     as shipment_date,
        units_shipped::number      as units_shipped,
        upper(trim(region))        as region
    from source

)

select * from final
