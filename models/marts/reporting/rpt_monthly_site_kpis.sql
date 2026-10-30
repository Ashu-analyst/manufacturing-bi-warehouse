-- Board / Power BI layer: one row per site and month with the KPIs leadership asks for.
with sales as (
    select st.site_name, d.year, d.month, d.month_label,
           sum(f.net_amount_eur)                                       as revenue_eur,
           sum(case when f.is_return then -f.net_amount_eur else 0 end) as returns_eur,
           sum(f.price_variance_eur)                                   as price_variance_eur
    from {{ ref('fct_sales') }} f
    join {{ ref('dim_date') }} d on d.date_key = f.order_date_key
    join {{ ref('dim_site') }} st using (site_key)
    group by all
),
prod as (
    select st.site_name, d.year, d.month,
           count(*)                                          as batches,
           avg(case when p.is_rejected then 1.0 else 0 end)  as reject_rate,
           sum(p.actual_qty_kg) / nullif(sum(p.planned_qty_kg), 0) as yield,
           avg(p.cycle_time_h)                               as avg_cycle_time_h
    from {{ ref('fct_production') }} p
    join {{ ref('dim_date') }} d on d.date_key = p.production_date_key
    join {{ ref('dim_site') }} st using (site_key)
    group by all
)
select
    s.site_name, s.year, s.month, s.month_label,
    round(s.revenue_eur, 0)          as revenue_eur,
    round(s.returns_eur, 0)          as returns_eur,
    round(s.price_variance_eur, 0)   as price_variance_eur,
    p.batches,
    round(p.reject_rate, 3)          as reject_rate,
    round(p.yield, 3)                as yield,
    round(p.avg_cycle_time_h, 1)     as avg_cycle_time_h
from sales s
left join prod p using (site_name, year, month)
order by s.site_name, s.year, s.month
