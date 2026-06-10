with source as (

    select
        "patient_key"               as patient_key,
        "patient_chartnumber_pkey"  as patient_chartnumber_pkey,
        "v_appt_pkey"               as v_appt_pkey,
        "v_dos"                     as v_dos,
        "visit_number"              as visit_number,
        "last_episode_first_visit"  as last_episode_first_visit,
        "last_episode_latest_visit" as last_episode_latest_visit,
        "v_discipline"              as v_discipline,
        "v_appt_types"              as v_appt_types,
        "v_visit_modality"          as v_visit_modality,
        "clinician_pgprof_key"      as clinician_pgprof_key,
        "clinician_name"            as clinician_name,
        "clinician_type"            as clinician_type,
        "v_region"                  as v_region,
        "v_state"                   as v_state
    from {{ source('lifestance_raw', 'last_episode_of_care') }}

),

final as (

    select
        trim(patient_key)               as patient_key,
        trim(patient_chartnumber_pkey)  as patient_chartnumber_key,
        trim(v_appt_pkey)               as appointment_key,
        v_dos::date                     as date_of_service,
        visit_number::number            as visit_number,
        last_episode_first_visit::date  as episode_first_visit_date,
        last_episode_latest_visit::date as episode_latest_visit_date,
        trim(v_discipline)              as discipline,
        trim(v_appt_types)              as appointment_type,
        trim(v_visit_modality)          as visit_modality,
        trim(clinician_pgprof_key)      as clinician_key,
        trim(clinician_name)            as clinician_name,
        trim(clinician_type)            as clinician_type,
        trim(v_region)                  as region,
        trim(v_state)                   as state
    from source

)

select * from final
