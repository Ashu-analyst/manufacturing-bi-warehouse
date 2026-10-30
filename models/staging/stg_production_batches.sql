select
    batch_no                         as batch_id,
    site_code                        as site_id,
    material_no                      as product_id,
    cast(production_date as date)    as production_date,
    planned_qty_kg,
    actual_qty_kg,
    upper(qc_status)                 as qc_status,
    cycle_time_h
from {{ ref('raw_production_batches') }}
