
with source as (

    select * from {{ source('edwards_lifesciences_raw', 'raw_production_batches') }}

),

final as (

    select
        trim(batch_id)                    as batch_id,
        trim(product_id)                  as product_id,
        upper(trim(business_unit))        as business_unit,
        trim(manufacturing_site_id)       as manufacturing_site_id,
        to_date(production_date)          as production_date,
        units_produced::number            as units_produced,
        units_reworked::number            as units_reworked,
        units_scrapped::number            as units_scrapped
    from source

)

select * from final
