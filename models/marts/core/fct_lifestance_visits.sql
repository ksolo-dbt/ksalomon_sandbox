with visits as (

    select * from {{ ref('stg_lifestance_last_episode_of_care') }}

),

clinicians as (

    select * from {{ ref('stg_lifestance_clinicians') }}

),

outcomes_review as (

    select
        patient_key,
        appointment_key,
        boolor_agg(outcomes_reviewed is not null) as outcomes_reviewed,
        boolor_agg(ccp_utilized) as ccp_utilized
    from {{ ref('stg_lifestance_outcomes_review_ccp') }}
    group by 1, 2

),

final as (

    select
        visits.appointment_key,
        visits.patient_key,
        visits.patient_chartnumber_key,
        visits.clinician_key,
        visits.date_of_service,
        date_trunc('month', visits.date_of_service) as service_month,
        visits.visit_number,
        datediff(day, visits.episode_first_visit_date, visits.date_of_service) + 1 as episode_day_number,
        visits.episode_first_visit_date,
        visits.episode_latest_visit_date,
        visits.discipline,
        visits.appointment_type,
        visits.visit_modality,
        visits.region as service_region,
        visits.state as service_state,
        visits.clinician_name,
        coalesce(clinicians.clinician_type, visits.clinician_type) as clinician_type,
        clinicians.expected_discipline,
        clinicians.clinician_status,
        clinicians.clinician_months_tenure,
        coalesce(outcomes_review.outcomes_reviewed, false) as outcomes_reviewed,
        coalesce(outcomes_review.ccp_utilized, false) as ccp_utilized,
        iff(coalesce(outcomes_review.outcomes_reviewed, false), 1, 0) as outcomes_reviewed_count,
        iff(coalesce(outcomes_review.ccp_utilized, false), 1, 0) as ccp_utilized_count,
        1 as visit_count
    from visits
    left join clinicians
        on visits.clinician_key = clinicians.clinician_key
    left join outcomes_review
        on visits.patient_key = outcomes_review.patient_key
        and visits.appointment_key = outcomes_review.appointment_key

)

select * from final
