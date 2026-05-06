
with source as (

    select * from {{ source('edwards_lifesciences_raw', 'raw_hospital_accounts') }}

),

final as (

    select
        trim(hospital_id)              as hospital_id,
        trim(hospital_name)            as hospital_name,
        upper(trim(region))            as region,
        trim(country)                  as country,
        is_teaching_hospital::boolean  as is_teaching_hospital,
        trim(primary_specialty)        as primary_specialty
    from source

)

select * from final
