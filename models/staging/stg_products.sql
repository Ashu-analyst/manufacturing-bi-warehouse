select
    material_no          as product_id,
    material_desc        as product_name,
    product_group,
    lower(base_uom)      as unit_of_measure,
    std_price_eur
from {{ ref('raw_products') }}
