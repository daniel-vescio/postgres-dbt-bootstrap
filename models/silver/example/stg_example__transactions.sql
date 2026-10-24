with source as (
    select * from {{ ref('example_transactions') }}
),

cleaned as (
    select
        transaction_id,
        account_id,
        transacted_at,
        amount,
        merchant,
        upper(currency) as currency,
        lower(category) as category,
        case when amount < 0 then 'debit' else 'credit' end as direction
    from source
)

select * from cleaned
