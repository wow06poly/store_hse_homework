select
    o.order_id,
    o.order_amount,
    sum(i.line_amount) as items_amount
from {{ ref('fct_orders') }} as o
join {{ ref('fct_order_items') }} as i
    on i.order_id = o.order_id
group by o.order_id, o.order_amount
having o.order_amount <> sum(i.line_amount)
