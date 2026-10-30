-- Reconciliation test: revenue in the fact must equal the de-duplicated source extract.
with src as (
    select sum(quantity * unit_price) as amt
    from (select distinct * from {{ ref('raw_sales_order_lines') }})
),
fct as (select sum(net_amount_eur) as amt from {{ ref('fct_sales') }})
select src.amt as source_amt, fct.amt as fact_amt
from src, fct
where abs(src.amt - fct.amt) > 0.01
