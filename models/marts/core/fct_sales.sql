-- Grain: one row per sales order line. Additive measures only; prices live in the dimension.
select
    s.order_line_id,
    cast(strftime(s.order_date, '%Y%m%d') as integer) as order_date_key,
    c.customer_key,
    p.product_key,
    st.site_key,
    s.order_no,
    s.quantity                                       as quantity_kg,
    s.net_amount_eur,
    s.quantity * p.std_price_eur                     as standard_value_eur,
    s.net_amount_eur - s.quantity * p.std_price_eur  as price_variance_eur,
    s.is_return
from {{ ref('stg_sales_order_lines') }} s
join {{ ref('dim_customer') }} c using (customer_id)
join {{ ref('dim_product') }}  p using (product_id)
join {{ ref('dim_site') }}     st using (site_id)
