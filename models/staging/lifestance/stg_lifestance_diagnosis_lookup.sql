with source as (

    select
        "diagnosiscode" as diagnosiscode,
        "dx_group"      as dx_group
    from {{ source('lifestance_raw', 'diagnosis_lookup') }}

),

final as (

    select
        trim(diagnosiscode) as diagnosis_code,
        trim(dx_group)      as diagnosis_group
    from source

)

select * from final
