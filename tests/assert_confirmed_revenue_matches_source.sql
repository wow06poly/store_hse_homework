with source_payments as (
    select
        order_id,
        count(*) filter (
            where payment_status = 'success' and amount > 0
        ) as successful_payments_count
    from {{ source('shop', 'payments') }}
    group by order_id
),

source_total as (
    select coalesce(sum(o.total_amount), 0) as revenue
    from {{ source('shop', 'orders') }} as o
    left join source_payments as p
        on p.order_id = o.order_id
    where o.status = 'paid'
      and coalesce(p.successful_payments_count, 0) > 0
),

mart_total as (
    select coalesce(sum(order_amount), 0) as revenue
    from {{ ref('fct_orders') }}
    where is_confirmed
)

select
    source_total.revenue as source_revenue,
    mart_total.revenue as mart_revenue
from source_total
cross join mart_total
where source_total.revenue <> mart_total.revenue
