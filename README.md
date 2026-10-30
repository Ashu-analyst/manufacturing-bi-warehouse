# Manufacturing BI Warehouse (dbt + dimensional model)

A Kimball-style **star-schema data warehouse** for a multi-site manufacturer, built with **dbt**. It turns raw ERP extracts into tested, documented fact and dimension tables and a KPI layer ready for Power BI. Data-quality checks run in CI and stop bad data from reaching dashboards.

> The data is **synthetic** (`scripts/generate_erp_extracts.py`): 4 production sites in DE / NO / PE, 6 products (omega-3 / specialty oils), 60 B2B customers, ~2.9k order lines and ~1.7k production batches, Jan 2024 – Sep 2026. Real-world data problems are injected on purpose (see below).

## Why

Most BI teams start with every report querying the ERP in its own way, and three dashboards show three different revenue numbers. This project shows the alternative: **one modelled layer, one definition per KPI, tests that fail loudly.**

## Architecture

```
ERP extracts (seeds/)         staging/ (views)               marts/core/ (tables)          marts/reporting/
raw_customers        ──►  stg_customers   (clean, ISO-2) ──►  dim_customer  ─┐
raw_products         ──►  stg_products                   ──►  dim_product   ─┤
raw_sites            ──►  stg_sites                      ──►  dim_site      ─┼──►  rpt_monthly_site_kpis
raw_sales_order_lines──►  stg_sales_order_lines (dedup)  ──►  fct_sales     ─┤      (revenue, returns, price
raw_production_batches─►  stg_production_batches         ──►  fct_production─┤       variance, reject rate,
                                                              dim_date (generated) ┘   yield, cycle time)
                          snapshots/snap_customers  (SCD Type 2 history)
```

**Star schema**

| Table | Grain | Key measures |
|---|---|---|
| `fct_sales` | one sales order line | quantity_kg, net_amount_eur, standard_value_eur, price_variance_eur, is_return |
| `fct_production` | one production batch | planned / actual / released qty, is_rejected, cycle_time_h |
| `dim_date` | one day | year, quarter, month labels, weekend flag |
| `dim_customer`, `dim_product`, `dim_site` | one member | surrogate key + attributes |

## Data quality: problems injected and how they're handled

| Problem in the source | Where it's handled | Test that guards it |
|---|---|---|
| Duplicate extract row | `stg_sales_order_lines` (row_number dedup) | `unique` on order_line_id + **reconciliation test**: fact revenue = de-duplicated source |
| Country as `DE` / `de` / `Germany` | `normalise_country` macro → ISO-2, unknown → `XX` | `accepted_values` on country_code |
| Names in CAPS with trailing spaces | `title_case` + `fix_legal_suffix` macros (`HEALTH BV ` → `Health BV`) | (visual check; original kept in `customer_name_original`) |
| Returns as negative quantity | kept, flagged `is_return` | KPI `returns_eur` in reporting |
| Orphan keys between tables | joins in facts | `relationships` tests to every dimension |
| Impossible production yield | n/a | singular test `assert_yield_within_bounds` (50–110% of plan) |

`dbt build` result: **50 of 50 passed** (5 seeds, 12 models, 1 snapshot, 32 data tests).

## Run it

```bash
pip install -r requirements.txt
export DBT_PROFILES_DIR=.
python scripts/generate_erp_extracts.py   # optional: regenerate source data
dbt build                                  # seeds + models + tests
dbt snapshot                               # SCD2 customer history
dbt docs generate && dbt docs serve        # lineage graph + column docs
```

Query the result (DuckDB):

```sql
select site_name, year, sum(revenue_eur) revenue, avg(reject_rate) reject_rate, avg(yield) yield
from main_reporting.rpt_monthly_site_kpis group by all order by 1, 2;
```

## Production on Azure

See [`docs/AZURE.md`](docs/AZURE.md): Azure Data Factory copies ERP tables to ADLS, dbt (`dbt-fabric` / `dbt-synapse`) builds the same models, failed tests stop the Power BI refresh, and Power BI uses the star schema in Import or Direct Lake mode.

## Design decisions

- **Staging = views, marts = tables.** Staging is cheap and always current. Marts are materialised for fast BI.
- **Surrogate keys (md5)** on dimensions, so facts don't depend on ERP numbering and SCD2 history can be added without changing facts.
- **Integer date keys** (`20260930`), which compress well in Power BI and are easy to join.
- **No package dependencies.** Small macros replace `dbt_utils`, so CI is fast and stable.
- **Business rules in one place**: price variance and yield are defined once in SQL, not re-implemented in every DAX measure.

## Next steps

- Incremental models for `fct_sales` (merge on `order_line_id`) once volumes grow
- Source freshness checks (`dbt source freshness`) on the nightly copy
- Power BI semantic model with RLS by site, plus a deployment pipeline (dev → test → prod)
