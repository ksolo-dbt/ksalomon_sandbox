with source as (

    select
        "patient_uid"               as patient_uid,
        "licensekey"                as licensekey,
        "patient_pkey"              as patient_pkey,
        "patient_chartnumber_pkey"  as patient_chartnumber_pkey,
        "patient_first_name"        as patient_first_name,
        "patient_last_name"         as patient_last_name,
        "patient_dob"               as patient_dob,
        "patient_age"               as patient_age,
        "patient_gender"            as patient_gender,
        "patient_marital_status"    as patient_marital_status,
        "patient_race"              as patient_race,
        "patient_region"            as patient_region,
        "patient_state"             as patient_state
    from {{ source('lifestance_raw', 'patients') }}

),

final as (

    select
        patient_uid,
        trim(licensekey)                as licensekey,
        trim(patient_pkey)              as patient_key,
        trim(patient_chartnumber_pkey)  as patient_chartnumber_key,
        trim(patient_first_name)        as patient_first_name,
        trim(patient_last_name)         as patient_last_name,
        patient_dob::date               as patient_dob,
        patient_age::number             as patient_age,
        trim(patient_gender)            as patient_gender,
        trim(patient_marital_status)    as patient_marital_status,
        trim(patient_race)              as patient_race,
        trim(patient_region)            as patient_region,
        trim(patient_state)             as patient_state
    from source

)

select * from final
