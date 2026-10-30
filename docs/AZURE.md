# Running this on Azure (Data Factory / Fabric + Power BI)

The local project uses DuckDB so anyone can run it in two minutes. The same layering maps 1:1 to an Azure stack:

| Layer | Local (this repo) | Azure production |
|---|---|---|
| Ingest | `scripts/generate_erp_extracts.py` → `seeds/` | **Azure Data Factory** (or Fabric Data Pipeline) Copy activity: ERP (SAP / Navision via self-hosted integration runtime) → ADLS Gen2 `raw/` as Parquet, nightly trigger |
| Raw layer | dbt seeds (`main_raw`) | ADLS `raw/` exposed as external tables, or a Fabric Lakehouse |
| Transform | `dbt build` on DuckDB | `dbt build` with **dbt-fabric**, **dbt-synapse** or **dbt-sqlserver** adapter, run by an ADF pipeline step (Azure Container Instance / DevOps agent) after the copy succeeds |
| Data quality | 32 dbt data tests (fail the build) | Same tests; on failure the ADF pipeline stops before the reporting layer refreshes and alerts the data owner (Teams / email) |
| History | `dbt snapshot` (SCD2 customers) | Same, scheduled daily |
| Serve | `main_reporting.rpt_monthly_site_kpis` | Power BI semantic model in **Import** or **Direct Lake** mode on the `core` star schema; `reporting` tables for fixed board packs |
| Security | n/a | Entra ID groups, row-level security in Power BI by site/country |

**Orchestration order (one ADF pipeline):** Copy ERP tables → `dbt seed`/`source freshness` → `dbt build` → on success refresh the Power BI dataset (REST API activity) → on failure notify.

**Why the star schema matters for Power BI:** facts with integer date keys and surrogate keys to small dimensions are what the VertiPaq engine compresses best. DAX stays simple (`SUM`, `DIVIDE`, time intelligence on `dim_date`), and every report uses the same definition of "revenue" and "yield".
