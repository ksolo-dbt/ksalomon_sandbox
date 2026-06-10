with source as (

    select
        "clinician_pgprof_key"      as clinician_pgprof_key,
        "clinician_name"            as clinician_name,
        "clinician_type"            as clinician_type,
        "expected_discipline"       as expected_discipline,
        "clinician_status"          as clinician_status,
        "clinician_months_tenure"   as clinician_months_tenure
    from {{ source('lifestance_raw', 'clinicians') }}

),

final as (

    select
        trim(clinician_pgprof_key)      as clinician_key,
        trim(clinician_name)            as clinician_name,
        trim(clinician_type)            as clinician_type,
        trim(expected_discipline)       as expected_discipline,
        trim(clinician_status)          as clinician_status,
        clinician_months_tenure::number as clinician_months_tenure
    from source

)

select * from final
