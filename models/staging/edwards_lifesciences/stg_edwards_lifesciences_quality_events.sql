
with source as (

    select * from {{ source('edwards_lifesciences_raw', 'raw_quality_events') }}

),

final as (

    select
        trim(event_id)             as event_id,
        trim(batch_id)             as batch_id,
        to_date(event_date)        as event_date,
        trim(event_type)           as event_type,
        upper(trim(severity))      as severity,
        trim(detected_at)          as detected_at,
        upper(trim(region))        as region
    from source

)

select * from final
