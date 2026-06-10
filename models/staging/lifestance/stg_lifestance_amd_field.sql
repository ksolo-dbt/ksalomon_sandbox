with source as (

    select
        "Field_UID"  as field_uid,
        "FieldName"  as field_name
    from {{ source('lifestance_raw', 'amd_field') }}

),

final as (

    select
        field_uid::number   as field_uid,
        trim(field_name)    as field_name
    from source

)

select * from final
