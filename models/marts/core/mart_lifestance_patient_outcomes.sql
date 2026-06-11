with assessments as (

    select * from {{ ref('fct_lifestance_outcome_assessments') }}

),

visits as (

    select * from {{ ref('fct_lifestance_visits') }}

),

patients as (

    select * from {{ ref('dim_lifestance_patients') }}

),

visit_summary as (

    select
        patient_key,
        min(episode_first_visit_date) as episode_first_visit_date,
        max(episode_latest_visit_date) as episode_latest_visit_date,
        count(distinct appointment_key) as total_visits,
        count(distinct service_month) as active_service_months,
        count(distinct visit_modality) as visit_modality_count,
        count(distinct discipline) as discipline_count,
        max(iff(visit_modality = 'In-person', 1, 0)) as has_in_person_visit,
        max(iff(visit_modality = 'Telehealth', 1, 0)) as has_telehealth_visit,
        max(iff(discipline = 'Psychiatry', 1, 0)) as has_psychiatry_visit,
        max(iff(discipline = 'Psychotherapy', 1, 0)) as has_psychotherapy_visit,
        sum(outcomes_reviewed_count) as outcomes_reviewed_visits,
        sum(ccp_utilized_count) as ccp_utilized_visits
    from visits
    group by 1

),

patient_baselines as (

    select
        patient_key,
        max(iff(measure_type = 'phq9' and assessment_sequence = 1, score, null)) as phq9_baseline_score,
        max(iff(measure_type = 'gad7' and assessment_sequence = 1, score, null)) as gad7_baseline_score
    from assessments
    group by 1

),

outcome_rollup as (

    select
        patient_key,
        measure_type,
        count(*) as total_assessments,
        max(iff(assessment_sequence = 1, score, null)) as baseline_score,
        max(iff(assessment_sequence = 1, measure_date, null)) as baseline_measure_date,
        max(iff(assessment_sequence = 1, measure_visit_number, null)) as baseline_visit_number,
        max(iff(assessment_sequence = 1, score_severity, null)) as baseline_severity,
        max(iff(assessment_sequence = 2, score, null)) as second_score,
        max(iff(assessment_sequence = 2, measure_date, null)) as second_measure_date,
        max(iff(assessment_sequence = 2, score_reduction_from_baseline, null)) as early_score_reduction,
        max(iff(reverse_assessment_sequence = 1, score, null)) as latest_score,
        max(iff(reverse_assessment_sequence = 1, measure_date, null)) as latest_measure_date,
        max(iff(reverse_assessment_sequence = 1, measure_visit_number, null)) as latest_visit_number,
        max(iff(reverse_assessment_sequence = 1, score_severity, null)) as latest_severity,
        max(significant_improvement_threshold) as significant_improvement_threshold
    from assessments
    group by 1, 2

),

final as (

    select
        md5(outcome_rollup.patient_key || '|' || outcome_rollup.measure_type) as patient_outcome_key,
        outcome_rollup.patient_key,
        outcome_rollup.measure_type,
        patients.patient_age_band,
        patients.patient_gender,
        patients.patient_race,
        patients.patient_marital_status,
        patients.patient_region,
        patients.patient_state,
        patients.diagnosis_groups,
        patients.diagnosis_code_count,
        patients.diagnosis_group_count,
        patients.diagnosis_complexity_segment,
        patients.has_depression_diagnosis,
        patients.has_anxiety_diagnosis,
        patients.has_ocd_diagnosis,
        patients.has_ptsd_diagnosis,
        patients.has_adhd_diagnosis,
        patients.has_bipolar_diagnosis,
        visit_summary.episode_first_visit_date,
        visit_summary.episode_latest_visit_date,
        datediff(day, visit_summary.episode_first_visit_date, visit_summary.episode_latest_visit_date) as episode_days,
        visit_summary.total_visits,
        round(
            div0(visit_summary.total_visits * 30.4375, nullif(datediff(day, visit_summary.episode_first_visit_date, visit_summary.episode_latest_visit_date), 0)),
            2
        ) as sessions_per_month,
        case
            when sessions_per_month >= 8 then 'High density'
            when sessions_per_month >= 4 then 'Medium density'
            when sessions_per_month > 0 then 'Low density'
            else 'No visit density'
        end as service_density_bucket,
        case
            when visit_summary.has_in_person_visit = 1 and visit_summary.has_telehealth_visit = 1 then 'Mixed modality'
            when visit_summary.has_in_person_visit = 1 then 'In-person only'
            when visit_summary.has_telehealth_visit = 1 then 'Telehealth only'
            else 'Unknown modality'
        end as visit_modality_mix,
        case
            when visit_summary.has_psychiatry_visit = 1 and visit_summary.has_psychotherapy_visit = 1 then 'Psychiatry + Psychotherapy'
            when visit_summary.has_psychiatry_visit = 1 then 'Psychiatry only'
            when visit_summary.has_psychotherapy_visit = 1 then 'Psychotherapy only'
            else 'Unknown discipline'
        end as discipline_mix,
        visit_summary.outcomes_reviewed_visits,
        visit_summary.ccp_utilized_visits,
        outcome_rollup.total_assessments,
        outcome_rollup.baseline_score,
        outcome_rollup.baseline_measure_date,
        outcome_rollup.baseline_visit_number,
        outcome_rollup.baseline_severity,
        outcome_rollup.second_score,
        outcome_rollup.second_measure_date,
        outcome_rollup.early_score_reduction,
        outcome_rollup.latest_score,
        outcome_rollup.latest_measure_date,
        outcome_rollup.latest_visit_number,
        outcome_rollup.latest_severity,
        outcome_rollup.baseline_score - outcome_rollup.latest_score as score_reduction,
        round(
            div0((outcome_rollup.baseline_score - outcome_rollup.latest_score) * 100, nullif(outcome_rollup.baseline_score, 0)),
            1
        ) as score_reduction_percent,
        iff(outcome_rollup.baseline_score - outcome_rollup.latest_score >= outcome_rollup.significant_improvement_threshold, 1, 0) as achieved_significant_improvement,
        iff(outcome_rollup.early_score_reduction >= outcome_rollup.significant_improvement_threshold, 1, 0) as achieved_early_significant_improvement,
        case
            when patient_baselines.phq9_baseline_score >= 20 and patient_baselines.gad7_baseline_score >= 15 then 'Severe depression + severe anxiety'
            when patient_baselines.phq9_baseline_score >= 15 and patient_baselines.gad7_baseline_score >= 10 then 'Elevated depression + anxiety'
            when patient_baselines.phq9_baseline_score >= 10 and coalesce(patient_baselines.gad7_baseline_score, 0) < 10 then 'Moderate+ depression only'
            when patient_baselines.gad7_baseline_score >= 10 and coalesce(patient_baselines.phq9_baseline_score, 0) < 10 then 'Moderate+ anxiety only'
            else 'Lower baseline severity'
        end as baseline_severity_profile,
        1 as patient_outcome_count
    from outcome_rollup
    inner join patients
        on outcome_rollup.patient_key = patients.patient_key
    left join visit_summary
        on outcome_rollup.patient_key = visit_summary.patient_key
    left join patient_baselines
        on outcome_rollup.patient_key = patient_baselines.patient_key

)

select * from final
