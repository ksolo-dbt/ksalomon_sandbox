with source as (

    select * from {{ source('tpch', 'region') }}

),

renamed as (

    select
        r_regionkey as region_key,
        r_name as name, -- noqa: RF04
        r_comment as comment -- noqa: RF04

    from source

)

select * from renamed
