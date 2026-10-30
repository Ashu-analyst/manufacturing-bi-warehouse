select
    {{ dbt_utils_surrogate_key(['customer_id']) }} as customer_key,
    customer_id,
    customer_name,
    country_code,
    industry
from {{ ref('stg_customers') }}
