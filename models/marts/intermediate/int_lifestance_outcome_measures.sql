with phr_outcomes as (

    select
        'phr'                                                       as collection_source,
        patient_fid || '-' || licensekey                           as patient_key,
        iff(appointment_fid is null, null, appointment_fid || '-' || licensekey) as appointment_key,
        phq9_score,
        phq9_date,
        gad7_score,
        gad7_date,
        first_submitted_at
    from {{ ref('stg_lifestance_amd_fieldvalue') }}

),

portal_outcomes as (

    select
        'portal'                                                    as collection_source,
        patient_fid || '-' || licensekey                           as patient_key,
        iff(appointment_fid is null, null, appointment_fid || '-' || licensekey) as appointment_key,
        phq9_score,
        phq9_date,
        gad7_score,
        gad7_date,
        first_submitted_at
    from {{ ref('stg_lifestance_amd_patientnotecontrol') }}

),

outcomes as (

    select * from phr_outcomes
    union all
    select * from portal_outcomes

),

unpivoted as (

    select
        collection_source,
        patient_key,
        appointment_key,
        'phq9'          as measure_type,
        phq9_date       as measure_date,
        phq9_score      as score,
        first_submitted_at
    from outcomes
    where phq9_score is not null
        and phq9_date is not null

    union all

    select
        collection_source,
        patient_key,
        appointment_key,
        'gad7'          as measure_type,
        gad7_date       as measure_date,
        gad7_score      as score,
        first_submitted_at
    from outcomes
    where gad7_score is not null
        and gad7_date is not null

),

episode_bounds as (

    select
        patient_key,
        min(date_of_service) as episode_first_visit_date,
        max(date_of_service) as episode_latest_visit_date
    from {{ ref('stg_lifestance_last_episode_of_care') }}
    group by 1

),

deduped as (

    select *
    from unpivoted
    qualify row_number() over (
        partition by patient_key, measure_type, measure_date
        order by
            case collection_source
                when 'phr' then 1
                else 2
            end,
            first_submitted_at,
            appointment_key
    ) = 1

),

episode_measures as (

    select
        deduped.collection_source,
        deduped.patient_key,
        deduped.appointment_key,
        deduped.measure_type,
        deduped.measure_date,
        deduped.score,
        deduped.first_submitted_at,
        episode_bounds.episode_first_visit_date,
        episode_bounds.episode_latest_visit_date
    from deduped
    inner join episode_bounds
        on deduped.patient_key = episode_bounds.patient_key
    where deduped.measure_date between dateadd(day, -30, episode_bounds.episode_first_visit_date)
        and episode_bounds.episode_latest_visit_date

),

assigned_visits as (

    select
        episode_measures.collection_source,
        episode_measures.patient_key,
        episode_measures.appointment_key,
        episode_measures.measure_type,
        episode_measures.measure_date,
        episode_measures.score,
        episode_measures.first_submitted_at,
        coalesce(
            min(case
                when visits.date_of_service >= episode_measures.measure_date
                    then visits.visit_number
            end),
            max(visits.visit_number)
        ) as measure_visit_number
    from episode_measures
    left join {{ ref('stg_lifestance_last_episode_of_care') }} as visits
        on episode_measures.patient_key = visits.patient_key
    group by
        episode_measures.collection_source,
        episode_measures.patient_key,
        episode_measures.appointment_key,
        episode_measures.measure_type,
        episode_measures.measure_date,
        episode_measures.score,
        episode_measures.first_submitted_at

),

final as (

    select
        collection_source,
        patient_key,
        appointment_key,
        measure_type,
        measure_date,
        score,
        measure_visit_number,
        first_submitted_at
    from assigned_visits

)

select * from final
