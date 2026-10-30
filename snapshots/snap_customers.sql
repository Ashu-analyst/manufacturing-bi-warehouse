{% snapshot snap_customers %}
{{ config(target_schema='snapshots', unique_key='customer_id', strategy='check',
          check_cols=['customer_name', 'country_code', 'industry']) }}
-- SCD Type 2 history of the customer master: when a customer changes industry or country,
-- the old row is closed (dbt_valid_to) and a new row opens. Facts can then report "as it was".
select * from {{ ref('stg_customers') }}
{% endsnapshot %}
