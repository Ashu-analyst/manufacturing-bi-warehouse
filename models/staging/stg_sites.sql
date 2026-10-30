select site_code as site_id, site_name, upper(country_code) as country_code
from {{ ref('raw_sites') }}
