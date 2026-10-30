select
    {{ dbt_utils_surrogate_key(['site_id']) }} as site_key,
    site_id, site_name, country_code
from {{ ref('stg_sites') }}
