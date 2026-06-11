with patients as (

    select * from {{ ref('stg_lifestance_patients') }}

),

diagnosis_visit_link as (

    select * from {{ ref('stg_lifestance_diagnosis_visit_link') }}

),

diagnosis_lookup as (

    select * from {{ ref('stg_lifestance_diagnosis_lookup') }}

),

patient_diagnoses as (

    select
        diagnosis_visit_link.patient_key,
        listagg(distinct diagnosis_visit_link.diagnosis_code, ', ')
            within group (order by diagnosis_visit_link.diagnosis_code) as diagnosis_codes,
        listagg(distinct diagnosis_lookup.diagnosis_group, ', ')
            within group (order by diagnosis_lookup.diagnosis_group) as diagnosis_groups,
        count(distinct diagnosis_visit_link.diagnosis_code) as diagnosis_code_count,
        count(distinct diagnosis_lookup.diagnosis_group) as diagnosis_group_count,
        max(iff(diagnosis_lookup.diagnosis_group = 'Depression', 1, 0)) as has_depression_diagnosis,
        max(iff(diagnosis_lookup.diagnosis_group = 'Anxiety', 1, 0)) as has_anxiety_diagnosis,
        max(iff(diagnosis_lookup.diagnosis_group = 'OCD', 1, 0)) as has_ocd_diagnosis,
        max(iff(diagnosis_lookup.diagnosis_group = 'PTSD', 1, 0)) as has_ptsd_diagnosis,
        max(iff(diagnosis_lookup.diagnosis_group = 'ADHD', 1, 0)) as has_adhd_diagnosis,
        max(iff(diagnosis_lookup.diagnosis_group = 'Bipolar', 1, 0)) as has_bipolar_diagnosis
    from diagnosis_visit_link
    left join diagnosis_lookup
        on diagnosis_visit_link.diagnosis_code = diagnosis_lookup.diagnosis_code
    group by 1

),

final as (

    select
        patients.patient_key,
        patients.patient_chartnumber_key,
        trim(patients.patient_first_name || ' ' || patients.patient_last_name) as patient_full_name,
        patients.patient_age,
        case
            when patients.patient_age < 18 then 'Under 18'
            when patients.patient_age < 35 then '18-34'
            when patients.patient_age < 50 then '35-49'
            when patients.patient_age < 65 then '50-64'
            else '65+'
        end as patient_age_band,
        patients.patient_gender,
        patients.patient_marital_status,
        patients.patient_race,
        patients.patient_region,
        patients.patient_state,
        coalesce(patient_diagnoses.diagnosis_codes, '') as diagnosis_codes,
        coalesce(patient_diagnoses.diagnosis_groups, '') as diagnosis_groups,
        coalesce(patient_diagnoses.diagnosis_code_count, 0) as diagnosis_code_count,
        coalesce(patient_diagnoses.diagnosis_group_count, 0) as diagnosis_group_count,
        case
            when coalesce(patient_diagnoses.diagnosis_group_count, 0) >= 3 then '3+ diagnosis groups'
            when coalesce(patient_diagnoses.diagnosis_group_count, 0) = 2 then '2 diagnosis groups'
            when coalesce(patient_diagnoses.diagnosis_group_count, 0) = 1 then '1 diagnosis group'
            else 'No diagnosis group'
        end as diagnosis_complexity_segment,
        coalesce(patient_diagnoses.has_depression_diagnosis, 0) as has_depression_diagnosis,
        coalesce(patient_diagnoses.has_anxiety_diagnosis, 0) as has_anxiety_diagnosis,
        coalesce(patient_diagnoses.has_ocd_diagnosis, 0) as has_ocd_diagnosis,
        coalesce(patient_diagnoses.has_ptsd_diagnosis, 0) as has_ptsd_diagnosis,
        coalesce(patient_diagnoses.has_adhd_diagnosis, 0) as has_adhd_diagnosis,
        coalesce(patient_diagnoses.has_bipolar_diagnosis, 0) as has_bipolar_diagnosis
    from patients
    left join patient_diagnoses
        on patients.patient_key = patient_diagnoses.patient_key

)

select * from final
