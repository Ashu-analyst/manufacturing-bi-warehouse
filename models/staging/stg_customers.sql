-- Clean customer master: collapse whitespace, consistent casing, ISO-2 country codes.
with src as (select * from {{ ref('raw_customers') }})
select
    customer_no                                                        as customer_id,
    regexp_replace(trim(customer_name), '\s+', ' ', 'g')               as customer_name_original,
    -- one consistent display form for dashboards; the legal name stays in the ERP
    {{ fix_legal_suffix(title_case("regexp_replace(trim(customer_name), '\\s+', ' ', 'g')")) }} as customer_name,
    {{ normalise_country('country') }}                                 as country_code,
    industry
from src
