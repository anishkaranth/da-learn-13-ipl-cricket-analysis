# Build guide (Power BI Desktop)

1. **Get data.** Use Get data → Text/CSV and load every file in `powerbi/data/`. For the full data, first run `python scripts/download_full_data.py && python run_pipeline.py --source full`, then load the full tables from `data/clean_full/`.
2. **Types.** In Power Query, set `match_date` to Date, all `*_key`, `*_flag`, runs and wickets columns to Whole number, and everything else to Text.
3. **Batter and Bowler tables.** Duplicate `dim_player` and rename the copies `Batter` and `Bowler`.
4. **Relationships.** Create them as listed in [model.md](model.md). Mark the extra team relationships as inactive.
5. **Measures.** Create a blank `_Measures` table and paste each line of [measures.dax](measures.dax) as a new measure. Format the % measures as percentages with 2 decimals, and Run Rate and Economy with 2 decimals.
6. **Report.** Build the three pages in [dashboard_spec.md](dashboard_spec.md). Use one accent colour (#1f6f8b) to match `results/charts/dashboard.svg`.
7. **Check.** On the full data the cards should show the expected values listed at the end of the spec. On the sample CSVs (2024 only) the numbers will differ.
8. Save the .pbix locally. It is not committed, because it needs Windows.
