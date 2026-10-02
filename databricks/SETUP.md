# Databricks setup

Tested on Databricks SQL Serverless (Serverless Starter Warehouse) with Unity Catalog.

1. Create the schema and volume. Step 1 of the notebook does this too:
   ```sql
   CREATE SCHEMA IF NOT EXISTS workspace.da_learn_13;
   CREATE VOLUME IF NOT EXISTS workspace.da_learn_13.raw;
   ```
2. Upload `matches_2008-2024.csv` and `deliveries_2008-2024.csv` (from `scripts/download_full_data.py`) to `/Volumes/workspace/da_learn_13/raw/`. Use Catalog Explorer → Upload, or `databricks fs cp`.
3. Import `ipl_pipeline_notebook.sql` (Workspace → Import → File) and run all cells on a SQL warehouse. It reads the files with `read_files(...)` and builds `stg_*`, `clean_*`, the star tables, the `a_*` analysis tables and the `dq_*` checks in `workspace.da_learn_13`.
4. Import `ipl_cricket_dashboard.lvdash.json` (Dashboards → Create → Import), pick a warehouse, and publish. The dashboard has 2 counters (matches, run rate) and 6 charts: win % by franchise, season scoring, toss decision, top batters, top bowlers, and venue bat-first %.

## Verified run (2 Oct 2026, IST)
- The 35 statements ran in 204 s, starting at 21:26 IST.
- The dashboard "da-learn-13 IPL cricket analysis" was published at 21:42 IST in /Shared/da-learn-13-ipl-cricket-analysis/.
- `run_outputs/duckdb_vs_databricks.json` shows that the row counts of all 10 tables match DuckDB, with 0 cell differences in the KPI, assertion and analysis tables.
