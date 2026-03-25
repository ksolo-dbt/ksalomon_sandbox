with 

source as (

    select * from {{ source('movie_reviews', 'raw_movie_reviews') }}

),

renamed as (

    select
        'movie reviews' as from_table,
        id as movie_review_id,
        movie_id,
        response_time as review_time,
        review_text as review_txt,
    case 
        when sentiment_value = 0 then -2
        else 2
    end as actual_sentiment

    from source

)

select * from renamed