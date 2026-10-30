-- Conformed calendar dimension (daily grain). Generated, not loaded.
with days as (
    select unnest(generate_series(date '2024-01-01', date '2026-12-31', interval 1 day))::date as date_day
)
select
    cast(strftime(date_day, '%Y%m%d') as integer)  as date_key,
    date_day,
    year(date_day)                                 as year,
    quarter(date_day)                              as quarter,
    'Q' || quarter(date_day) || ' ' || year(date_day) as quarter_label,
    month(date_day)                                as month,
    strftime(date_day, '%b %Y')                    as month_label,
    isodow(date_day)                               as iso_day_of_week,
    isodow(date_day) >= 6                          as is_weekend
from days
