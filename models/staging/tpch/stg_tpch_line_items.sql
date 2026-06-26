with source as (

    select * from {{ source('tpch_now', 'lineitem') }}

),

renamed as (

    select

        {{ dbt_utils.generate_surrogate_key(
            ['l_orderkey', 
            'l_linenumber']) }}
            as order_item_key,
        l_orderkey as order_key,
        l_partkey as part_key,
        l_suppkey as supplier_key,
        l_linenumber as line_number,
        l_quantity as quantity,
        l_extendedprice as extended_price,
        l_discount as discount_percentage,
        l_tax as tax_rate,

        case
            when l_returnflag = 'R' then 'returned'
            when l_returnflag = 'A' then 'accepted'
            when l_returnflag = 'N' then 'not_returned'
            else 'unknown'
        end as return_flag,

<<<<<<< HEAD
        coalesce(l_returnflag = 'R', false) as is_returned,
=======
        return_flag != 'accepted' as is_return,
>>>>>>> 37ea214fd0627a5514367bb2b2f666b3f9e77135

        case l_linestatus
            when 'P' then 'returned'
            when 'F' then 'billed'
            when 'O' then 'shipped'
        end as status_code,

        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,
        l_shipinstruct as ship_instructions,
        l_shipmode as ship_mode,
        l_comment as comment -- noqa: RF04

    from source

)

select
    order_item_key,
    order_key,
    part_key,
    supplier_key,
    line_number,
    quantity,
    extended_price,
    discount_percentage,
    tax_rate,
    return_flag,
    is_returned,
    status_code,
    ship_date,
    commit_date,
    receipt_date,
    ship_instructions,
    ship_mode,
    comment
from renamed
