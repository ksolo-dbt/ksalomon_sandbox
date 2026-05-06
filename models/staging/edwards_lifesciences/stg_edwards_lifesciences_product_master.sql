
with source as (

    select * from {{ source('edwards_lifesciences_raw', 'raw_product_master') }}

),

final as (

    select
        trim(product_id)           as product_id,
        trim(product_name)         as product_name,
        upper(trim(business_unit)) as business_unit,
        trim(device_family)        as device_family,
        trim(udi_root)             as udi_root,
        launch_year::number        as launch_year
    from source

)

select * from final
