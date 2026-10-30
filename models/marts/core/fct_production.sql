-- Grain: one row per production batch.
select
    b.batch_id,
    cast(strftime(b.production_date, '%Y%m%d') as integer) as production_date_key,
    p.product_key,
    st.site_key,
    b.planned_qty_kg,
    b.actual_qty_kg,
    case when b.qc_status = 'RELEASED' then b.actual_qty_kg else 0 end as released_qty_kg,
    b.qc_status = 'REJECTED'                                as is_rejected,
    b.cycle_time_h
from {{ ref('stg_production_batches') }} b
join {{ ref('dim_product') }} p using (product_id)
join {{ ref('dim_site') }}    st using (site_id)
