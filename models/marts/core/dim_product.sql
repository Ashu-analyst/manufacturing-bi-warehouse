select
    {{ dbt_utils_surrogate_key(['product_id']) }} as product_key,
    product_id, product_name, product_group, unit_of_measure, std_price_eur
from {{ ref('stg_products') }}
