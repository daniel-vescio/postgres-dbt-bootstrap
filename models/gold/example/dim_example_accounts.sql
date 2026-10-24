with account_history as (
    select * from {{ ref('snap_example_accounts') }}
),

current_accounts as (
    select
        account_id,
        customer_id,
        account_type,
        status,
        opened_on,
        dbt_valid_from as valid_from
    from account_history
    where dbt_valid_to is null
)

select * from current_accounts
