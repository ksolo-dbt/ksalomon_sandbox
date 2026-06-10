with source as (

    select
        "patient_key"   as patient_key,
        "v_appt_pkey"   as v_appt_pkey,
        "diagnosiscode" as diagnosiscode
    from {{ source('lifestance_raw', 'diagnosis_visit_link') }}

),

final as (

    select
        trim(patient_key)   as patient_key,
        trim(v_appt_pkey)   as appointment_key,
        trim(diagnosiscode) as diagnosis_code
    from source

)

select * from final
