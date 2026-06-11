{{
    config(
        enabled=true,
        severity='error',
        tags=['lifestance', 'cqo', 'demo']
    )
}}

with model_minus_source as (

    select
        'model_minus_source' as mismatch_side,
        model_rows.*
    from (
        select * from {{ ref('cqo_phq9_gad7_patient_level') }}
        except
        select * from {{ source('lifestance_raw', 'cqo_phq9_gad7_patient_level') }}
    ) as model_rows

),

source_minus_model as (

    select
        'source_minus_model' as mismatch_side,
        source_rows.*
    from (
        select * from {{ source('lifestance_raw', 'cqo_phq9_gad7_patient_level') }}
        except
        select * from {{ ref('cqo_phq9_gad7_patient_level') }}
    ) as source_rows

),

validation_errors as (

    select * from model_minus_source
    union all
    select * from source_minus_model

)

select * from validation_errors
