-- One row per order line. Removes exact duplicate extract rows; keeps returns but flags them.
with src as (
    select *,
           row_number() over (partition by order_no, line_no order by order_date) as rn
    from {{ ref('raw_sales_order_lines') }}
)
select
    order_no || '-' || cast(line_no as varchar)  as order_line_id,
    order_no,
    line_no,
    cast(order_date as date)                     as order_date,
    customer_no                                  as customer_id,
    material_no                                  as product_id,
    site_code                                    as site_id,
    quantity,
    unit_price,
    quantity * unit_price                        as net_amount_eur,
    quantity < 0                                 as is_return
from src
where rn = 1
