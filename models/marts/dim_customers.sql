{{ config(distributed_replicated=true) }}

with confirmed_orders as (
    select *
    from {{ ref('fct_orders') }}
    where is_confirmed
),

first_orders as (
    select
        customer_id,
        order_id,
        ordered_at,
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as order_number
    from confirmed_orders
),

customer_metrics as (
    select
        customer_id,
        count(*) as confirmed_orders_count,
        sum(order_amount) as confirmed_revenue
    from confirmed_orders
    group by customer_id
)

select
    c.customer_id,
    c.registered_at,
    c.registration_date,
    c.city,
    c.acquisition_channel,
    f.order_id as first_confirmed_order_id,
    f.ordered_at as first_confirmed_at,
    coalesce(m.confirmed_orders_count, 0) as confirmed_orders_count,
    coalesce(m.confirmed_revenue, 0) as confirmed_revenue,
    m.customer_id is not null as is_buyer
from {{ ref('stg_shop__customers') }} as c
left join first_orders as f
    on f.customer_id = c.customer_id
   and f.order_number = 1
left join customer_metrics as m
    on m.customer_id = c.customer_id
