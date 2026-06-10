with source as (

    select
        "licensekey"    as licensekey,
        "patientfid"    as patientfid,
        "appointmentfid" as appointmentfid,
        "FieldFID"      as field_fid,
        "value"         as value,
        "createdby"     as createdby,
        "createdat"     as createdat
    from {{ source('lifestance_raw', 'amd_fieldvalue_phq9_gad7_outcomes_phr') }}

),

-- Take the most recent submission when the same field is submitted multiple times
-- for the same patient + appointment combination
deduped as (

    select *
    from source
    qualify row_number() over (
        partition by patientfid, licensekey, appointmentfid, field_fid
        order by createdat desc
    ) = 1

),

-- Pivot EAV rows into columns; extract numeric scores from potentially messy strings
final as (

    select
        trim(licensekey)                                                as licensekey,
        patientfid::number                                              as patient_fid,
        trim(appointmentfid)                                            as appointment_fid,
        try_to_number(regexp_replace(
            max(case when field_fid = 1001 then value end), '[^0-9.]', '')
        )                                                               as phq9_score,
        try_to_date(max(case when field_fid = 1002 then value end))     as phq9_date,
        try_to_number(regexp_replace(
            max(case when field_fid = 1003 then value end), '[^0-9.]', '')
        )                                                               as gad7_score,
        try_to_date(max(case when field_fid = 1004 then value end))     as gad7_date,
        min(createdat)                                                  as first_submitted_at
    from deduped
    group by 1, 2, 3

)

select * from final
