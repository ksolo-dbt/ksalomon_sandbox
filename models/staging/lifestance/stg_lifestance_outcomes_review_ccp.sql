with source as (

    select
        "patient_key"                                       as patient_key,
        "v_appt_pkey"                                       as v_appt_pkey,
        "note_date"                                         as note_date,
        "outcomes_reviewed"                                 as outcomes_reviewed,
        "Clinical_Care_Pathway_was_utilized_or_referred_to" as ccp_utilized
    from {{ source('lifestance_raw', 'outcomes_review_ccp') }}

),

final as (

    select
        trim(patient_key)   as patient_key,
        trim(v_appt_pkey)   as appointment_key,
        note_date::date     as note_date,
        trim(outcomes_reviewed) as outcomes_reviewed,
        ccp_utilized
    from source

)

select * from final
