with measures as (

    select * from {{ ref('int_lifestance_outcome_measures') }}

),

sequenced as (

    select
        md5(
            patient_key || '|' || measure_type || '|' || measure_date::varchar
        ) as assessment_key,
        patient_key,
        appointment_key,
        collection_source,
        measure_type,
        measure_date,
        date_trunc('month', measure_date) as measure_month,
        score,
        measure_visit_number,
        first_submitted_at,
        row_number() over (
            partition by patient_key, measure_type
            order by measure_date, first_submitted_at, collection_source
        ) as assessment_sequence,
        row_number() over (
            partition by patient_key, measure_type
            order by measure_date desc, first_submitted_at desc, collection_source desc
        ) as reverse_assessment_sequence,
        first_value(score) over (
            partition by patient_key, measure_type
            order by measure_date, first_submitted_at, collection_source
        ) as baseline_score,
        first_value(measure_date) over (
            partition by patient_key, measure_type
            order by measure_date, first_submitted_at, collection_source
        ) as baseline_measure_date,
        lag(score) over (
            partition by patient_key, measure_type
            order by measure_date, first_submitted_at, collection_source
        ) as prior_score
    from measures

),

final as (

    select
        assessment_key,
        patient_key,
        appointment_key,
        collection_source,
        measure_type,
        measure_date,
        measure_month,
        score,
        measure_visit_number,
        assessment_sequence,
        'Assessment ' || assessment_sequence as assessment_sequence_label,
        reverse_assessment_sequence,
        baseline_score,
        baseline_measure_date,
        baseline_score - score as score_reduction_from_baseline,
        prior_score,
        prior_score - score as score_reduction_from_prior,
        case
            when measure_type = 'phq9' then 5
            when measure_type = 'gad7' then 4
        end as significant_improvement_threshold,
        case
            when measure_type = 'phq9' and score >= 20 then 'Severe'
            when measure_type = 'phq9' and score >= 15 then 'Moderately severe'
            when measure_type = 'phq9' and score >= 10 then 'Moderate'
            when measure_type = 'phq9' and score >= 5 then 'Mild'
            when measure_type = 'phq9' then 'Minimal'
            when measure_type = 'gad7' and score >= 15 then 'Severe'
            when measure_type = 'gad7' and score >= 10 then 'Moderate'
            when measure_type = 'gad7' and score >= 5 then 'Mild'
            when measure_type = 'gad7' then 'Minimal'
        end as score_severity,
        iff(
            assessment_sequence > 1
                and score <= baseline_score - significant_improvement_threshold,
            1,
            0
        ) as significant_improvement_from_baseline,
        iff(assessment_sequence = 2, 1, 0) as is_second_assessment,
        iff(reverse_assessment_sequence = 1, 1, 0) as is_latest_assessment,
        1 as assessment_count
    from sequenced

)

select * from final
