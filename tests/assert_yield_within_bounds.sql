-- Singular test: a batch can't produce more than 110% of plan or less than 50%.
-- Returns failing rows; dbt fails the test if any row comes back.
select batch_id, planned_qty_kg, actual_qty_kg
from {{ ref('fct_production') }}
where actual_qty_kg > planned_qty_kg * 1.10
   or actual_qty_kg < planned_qty_kg * 0.50
