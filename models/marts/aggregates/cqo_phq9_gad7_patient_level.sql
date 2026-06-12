--Comment to show changes
{{
    config(
        materialized = 'table'
    )
}}

with patients as (

    select * from {{ ref('stg_lifestance_patients') }}

),

visits as (

    select * from {{ ref('stg_lifestance_last_episode_of_care') }}

),

measures as (

    select * from {{ ref('int_lifestance_outcome_measures') }}

),

diagnosis_visit_link as (

    select * from {{ ref('stg_lifestance_diagnosis_visit_link') }}

),

diagnosis_lookup as (

    select * from {{ ref('stg_lifestance_diagnosis_lookup') }}

),

outcomes_review_ccp as (

    select * from {{ ref('stg_lifestance_outcomes_review_ccp') }}

),

episode_summary as (

    select
        patient_key,
        min(patient_chartnumber_key)        as patient_chartnumber_key,
        min(date_of_service)                as last_episode_first_visit,
        max(date_of_service)                as last_episode_latest_visit,
        count(distinct appointment_key)     as last_episode_total_visits
    from visits
    group by 1

),

sequenced_measures as (

    select
        patient_key,
        measure_type,
        measure_date,
        score,
        measure_visit_number,
        row_number() over (
            partition by patient_key, measure_type
            order by measure_date, first_submitted_at, collection_source
        ) as measure_sequence,
        row_number() over (
            partition by patient_key, measure_type
            order by measure_date desc, first_submitted_at desc, collection_source desc
        ) as reverse_measure_sequence
    from measures

),

measure_rollup as (

    select
        patient_key,
        measure_type,
        count(*)                                                        as total_measures,
        max(case when measure_sequence = 1 then score end)              as first_measure,
        max(case when measure_sequence = 1 then measure_date end)       as first_measure_date,
        max(case when measure_sequence = 1 then measure_visit_number end) as first_measure_visit_number,
        max(case when measure_sequence = 2 then score end)              as second_measure,
        max(case when reverse_measure_sequence = 1 then score end)      as last_measure,
        max(case when reverse_measure_sequence = 1 then measure_date end) as last_measure_date,
        max(case when reverse_measure_sequence = 1 then measure_visit_number end) as last_measure_visit_number
    from sequenced_measures
    group by 1, 2

),

measure_enriched as (

    select
        measure_rollup.*,
        measure_rollup.last_measure - measure_rollup.first_measure as difference_first_to_last,
        round(
            div0(
                (measure_rollup.last_measure - measure_rollup.first_measure) * 100,
                measure_rollup.first_measure
            ),
            1
        ) as change_from_first_measure_percent,
        datediff(day, measure_rollup.first_measure_date, measure_rollup.last_measure_date) as days_between_first_and_last,
        measure_rollup.last_measure_visit_number - measure_rollup.first_measure_visit_number as visits_between_first_and_last,
        iff(
            measure_rollup.first_measure >= 5
                and measure_rollup.first_measure_visit_number = 1
                and measure_rollup.total_measures >= 2
                and measure_rollup.last_measure_date > measure_rollup.first_measure_date,
            1,
            0
        ) as qualified_patient,
        case
            when measure_rollup.measure_type = 'phq9' and measure_rollup.first_measure >= 20 then 'Severe Depression: Score 20 - 27'
            when measure_rollup.measure_type = 'phq9' and measure_rollup.first_measure >= 15 then 'Moderately Severe Depression: Score 15 - 19'
            when measure_rollup.measure_type = 'phq9' and measure_rollup.first_measure >= 10 then 'Moderate Depression: Score 10 - 14'
            when measure_rollup.measure_type = 'phq9' and measure_rollup.first_measure >= 5 then 'Mild Depression: Score 5 - 9'
            when measure_rollup.measure_type = 'phq9' then 'Minimal Depression: Score 0 - 4'
            when measure_rollup.measure_type = 'gad7' and measure_rollup.first_measure >= 15 then 'Severe Anxiety: Score 15 - 21'
            when measure_rollup.measure_type = 'gad7' and measure_rollup.first_measure >= 10 then 'Moderate Anxiety: Score 10 - 14'
            when measure_rollup.measure_type = 'gad7' and measure_rollup.first_measure >= 5 then 'Mild Anxiety: Score 5 - 9'
            when measure_rollup.measure_type = 'gad7' then 'Minimal Anxiety: Score 0 - 4'
        end as first_measure_interpretation,
        case
            when measure_rollup.measure_type = 'phq9' and measure_rollup.last_measure >= 20 then 'Severe Depression: Score 20 - 27'
            when measure_rollup.measure_type = 'phq9' and measure_rollup.last_measure >= 15 then 'Moderately Severe Depression: Score 15 - 19'
            when measure_rollup.measure_type = 'phq9' and measure_rollup.last_measure >= 10 then 'Moderate Depression: Score 10 - 14'
            when measure_rollup.measure_type = 'phq9' and measure_rollup.last_measure >= 5 then 'Mild Depression: Score 5 - 9'
            when measure_rollup.measure_type = 'phq9' then 'Minimal Depression: Score 0 - 4'
            when measure_rollup.measure_type = 'gad7' and measure_rollup.last_measure >= 15 then 'Severe Anxiety: Score 15 - 21'
            when measure_rollup.measure_type = 'gad7' and measure_rollup.last_measure >= 10 then 'Moderate Anxiety: Score 10 - 14'
            when measure_rollup.measure_type = 'gad7' and measure_rollup.last_measure >= 5 then 'Mild Anxiety: Score 5 - 9'
            when measure_rollup.measure_type = 'gad7' then 'Minimal Anxiety: Score 0 - 4'
        end as last_measure_interpretation,
        case
            when measure_rollup.measure_type = 'phq9' then 5
            when measure_rollup.measure_type = 'gad7' then 4
        end as mcid_threshold
    from measure_rollup

),

measure_outcomes as (

    select
        measure_enriched.*,
        iff(
            measure_enriched.last_measure <= measure_enriched.first_measure - measure_enriched.mcid_threshold,
            1,
            0
        ) as achieved_mcid,
        iff(
            measure_enriched.last_measure <= measure_enriched.first_measure * 0.5,
            1,
            0
        ) as achieved_50pct_response,
        min(case
            when sequenced_measures.measure_sequence > 1
                and sequenced_measures.score <= measure_enriched.first_measure - measure_enriched.mcid_threshold
                then sequenced_measures.measure_visit_number
        end) as first_mcid_visit,
        min(case
            when sequenced_measures.measure_sequence > 1
                and sequenced_measures.score <= measure_enriched.first_measure - measure_enriched.mcid_threshold
                then sequenced_measures.measure_sequence
        end) as first_mcid_measure_sequence,
        iff(first_mcid_visit is not null, 1, 0) as achieved_first_mcid,
        min(case
            when sequenced_measures.measure_sequence > 1
                and measure_enriched.first_measure >= 5
                and sequenced_measures.score < 5
                then sequenced_measures.measure_visit_number
        end) as first_remission_visit,
        min(case
            when sequenced_measures.measure_sequence > 1
                and measure_enriched.first_measure >= 5
                and sequenced_measures.score < 5
                then sequenced_measures.measure_sequence
        end) as first_remission_measure_sequence,
        iff(first_remission_visit is not null, 1, 0) as achieved_first_remission
    from measure_enriched
    left join sequenced_measures
        on  measure_enriched.patient_key = sequenced_measures.patient_key
        and measure_enriched.measure_type = sequenced_measures.measure_type
    group by
        measure_enriched.patient_key,
        measure_enriched.measure_type,
        measure_enriched.total_measures,
        measure_enriched.first_measure,
        measure_enriched.first_measure_date,
        measure_enriched.first_measure_visit_number,
        measure_enriched.second_measure,
        measure_enriched.last_measure,
        measure_enriched.last_measure_date,
        measure_enriched.last_measure_visit_number,
        measure_enriched.difference_first_to_last,
        measure_enriched.change_from_first_measure_percent,
        measure_enriched.days_between_first_and_last,
        measure_enriched.visits_between_first_and_last,
        measure_enriched.qualified_patient,
        measure_enriched.first_measure_interpretation,
        measure_enriched.last_measure_interpretation,
        measure_enriched.mcid_threshold

),

measure_status as (

    select
        measure_outcomes.*,
        case
            when measure_outcomes.first_mcid_measure_sequence is null then null
            when not exists (
                select 1
                from sequenced_measures as later_measures
                where later_measures.patient_key = measure_outcomes.patient_key
                    and later_measures.measure_type = measure_outcomes.measure_type
                    and later_measures.measure_sequence > measure_outcomes.first_mcid_measure_sequence
            ) then 'First MCID not confirmed: no FU outcome'
            when exists (
                select 1
                from sequenced_measures as later_measures
                where later_measures.patient_key = measure_outcomes.patient_key
                    and later_measures.measure_type = measure_outcomes.measure_type
                    and later_measures.measure_sequence > measure_outcomes.first_mcid_measure_sequence
                    and later_measures.measure_visit_number > measure_outcomes.first_mcid_visit
                    and later_measures.score > measure_outcomes.first_measure - measure_outcomes.mcid_threshold
            ) then 'Declined after first mcid'
            when exists (
                select 1
                from sequenced_measures as later_measures
                where later_measures.patient_key = measure_outcomes.patient_key
                    and later_measures.measure_type = measure_outcomes.measure_type
                    and later_measures.measure_sequence > measure_outcomes.first_mcid_measure_sequence
                    and later_measures.measure_visit_number > measure_outcomes.first_mcid_visit
            ) then 'First MCID confirmed'
        end as first_mcid_status,
        iff(
            exists (
                select 1
                from sequenced_measures as later_measures
                where later_measures.patient_key = measure_outcomes.patient_key
                    and later_measures.measure_type = measure_outcomes.measure_type
                    and later_measures.measure_sequence > measure_outcomes.first_remission_measure_sequence
                    and later_measures.score >= 5
            ),
            'Declined after first remission',
            null
        ) as first_remission_status
    from measure_outcomes

),

phq9 as (

    select * from measure_status
    where measure_type = 'phq9'

),

gad7 as (

    select * from measure_status
    where measure_type = 'gad7'

),

diagnoses as (

    select
        diagnosis_visit_link.patient_key,
        listagg(distinct diagnosis_visit_link.diagnosis_code, ', ')
            within group (order by diagnosis_visit_link.diagnosis_code) as dx_codes,
        max(iff(diagnosis_lookup.diagnosis_group = 'Depression', 1, 0)) as depression,
        max(iff(diagnosis_lookup.diagnosis_group = 'Anxiety', 1, 0)) as anxiety_f41,
        max(iff(diagnosis_lookup.diagnosis_group = 'OCD', 1, 0)) as ocd_f42,
        max(iff(diagnosis_lookup.diagnosis_group = 'PTSD', 1, 0)) as adjustment_disorder_ptsd_f43,
        max(iff(diagnosis_lookup.diagnosis_group = 'ADHD', 1, 0)) as adhd_f90,
        max(iff(diagnosis_lookup.diagnosis_group = 'Bipolar', 1, 0)) as bipolar_disorder_f31
    from diagnosis_visit_link
    left join diagnosis_lookup
        on diagnosis_visit_link.diagnosis_code = diagnosis_lookup.diagnosis_code
    group by 1

),

ccp as (

    select
        patient_key,
        boolor_agg(ccp_utilized) as ccp_utilized,
        boolor_agg(outcomes_reviewed is not null) as outcomes_reviewed
    from outcomes_review_ccp
    group by 1

),

final as (

    select
        patients.patient_key,
        patients.patient_chartnumber_key as patient_chartnumber_pkey,
        trim(patients.patient_first_name || ' ' || patients.patient_last_name) as patient_fullname,
        patients.patient_age,
        patients.patient_gender,
        patients.patient_marital_status,
        patients.patient_race,
        patients.patient_state,
        episode_summary.last_episode_first_visit,
        episode_summary.last_episode_latest_visit,
        episode_summary.last_episode_total_visits,

        phq9.total_measures as phq9_total_measures,
        phq9.first_measure as phq9_first_measure,
        phq9.first_measure_date as phq9_first_measure_date,
        phq9.first_measure_visit_number as phq9_first_measure_visit_number,
        phq9.first_measure_interpretation as phq9_first_measure_interpretation,
        phq9.second_measure as phq9_second_measure,
        phq9.last_measure as phq9_last_measure,
        phq9.last_measure_date as phq9_last_measure_date,
        phq9.last_measure_visit_number as phq9_last_measure_visit_number,
        phq9.last_measure_interpretation as phq9_last_measure_interpretation,
        phq9.difference_first_to_last as phq9_difference_first_to_last,
        phq9.change_from_first_measure_percent as phq9_change_from_first_measure_percent,
        phq9.days_between_first_and_last as phq9_days_between_first_and_last,
        phq9.visits_between_first_and_last as phq9_visits_between_first_and_last,
        phq9.qualified_patient as phq9_qualified_patient,
        phq9.achieved_mcid as phq9_achieved_mcid,
        phq9.achieved_50pct_response as phq9_achieved_50pct_response,
        phq9.first_mcid_visit as phq9_first_mcid_visit,
        phq9.achieved_first_mcid as phq9_achieved_first_mcid,
        phq9.first_mcid_status as phq9_first_mcid_status,
        phq9.first_remission_visit as phq9_first_remission_visit,
        phq9.achieved_first_remission as phq9_achieved_first_remission,
        phq9.first_remission_status as phq9_first_remission_status,
        round((phq9.visits_between_first_and_last * 7) / nullif(phq9.days_between_first_and_last, 0), 3) as phq9_visit_frequency,

        gad7.total_measures as gad7_total_measures,
        gad7.first_measure as gad7_first_measure,
        gad7.first_measure_date as gad7_first_measure_date,
        gad7.first_measure_visit_number as gad7_first_measure_visit_number,
        gad7.first_measure_interpretation as gad7_first_measure_interpretation,
        gad7.second_measure as gad7_second_measure,
        gad7.last_measure as gad7_last_measure,
        gad7.last_measure_date as gad7_last_measure_date,
        gad7.last_measure_visit_number as gad7_last_measure_visit_number,
        gad7.last_measure_interpretation as gad7_last_measure_interpretation,
        gad7.difference_first_to_last as gad7_difference_first_to_last,
        gad7.change_from_first_measure_percent as gad7_change_from_first_measure_percent,
        gad7.days_between_first_and_last as gad7_days_between_first_and_last,
        gad7.visits_between_first_and_last as gad7_visits_between_first_and_last,
        gad7.qualified_patient as gad7_qualified_patient,
        gad7.achieved_mcid as gad7_achieved_mcid,
        gad7.achieved_50pct_response as gad7_achieved_50pct_response,
        gad7.first_mcid_visit as gad7_first_mcid_visit,
        gad7.achieved_first_mcid as gad7_achieved_first_mcid,
        gad7.first_mcid_status as gad7_first_mcid_status,
        gad7.first_remission_visit as gad7_first_remission_visit,
        gad7.achieved_first_remission as gad7_achieved_first_remission,
        gad7.first_remission_status as gad7_first_remission_status,
        round((gad7.visits_between_first_and_last * 7) / nullif(gad7.days_between_first_and_last, 0), 3) as gad7_visit_frequency,

        case
            when greatest(phq9.first_measure, gad7.first_measure) >= 15 then 'Moderately Severe/Severe: 15+'
            when greatest(phq9.first_measure, gad7.first_measure) >= 10 then 'Moderate: 10-14'
            when greatest(phq9.first_measure, gad7.first_measure) >= 5 then 'Mild: 5-9'
            else 'Minimal: 0-4'
        end as blended_first_score_interpretation,
        diagnoses.dx_codes,
        coalesce(diagnoses.depression, 0) as depression,
        coalesce(diagnoses.anxiety_f41, 0) as anxiety_f41,
        coalesce(diagnoses.ocd_f42, 0) as ocd_f42,
        coalesce(diagnoses.adjustment_disorder_ptsd_f43, 0) as adjustment_disorder_ptsd_f43,
        coalesce(diagnoses.adhd_f90, 0) as adhd_f90,
        coalesce(diagnoses.bipolar_disorder_f31, 0) as bipolar_disorder_f31,
        coalesce(ccp.ccp_utilized, false) as ccp_utilized,
        coalesce(ccp.outcomes_reviewed, false) as outcomes_reviewed
    from patients
    left join episode_summary
        on patients.patient_key = episode_summary.patient_key
    left join phq9
        on patients.patient_key = phq9.patient_key
    left join gad7
        on patients.patient_key = gad7.patient_key
    left join diagnoses
        on patients.patient_key = diagnoses.patient_key
    left join ccp
        on patients.patient_key = ccp.patient_key

)

select * from final
