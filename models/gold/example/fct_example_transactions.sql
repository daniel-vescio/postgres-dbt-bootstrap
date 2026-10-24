{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='delete+insert'
    )
}}

with transactions as (
    select * from {{ ref('stg_example__transactions') }}
    {% if is_incremental() %}
        -- Only rows newer than what's already loaded. `--full-refresh` rebuilds from scratch.
        where transacted_at > (select max(fct.transacted_at) from {{ this }} as fct)
    {% endif %}
),

final as (
    select
        transaction_id,
        account_id,
        transacted_at,
        amount,
        currency,
        direction,
        merchant,
        category,
        transacted_at::date as transaction_date
    from transactions
)

select * from final
