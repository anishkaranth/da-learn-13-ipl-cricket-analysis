-- 01_staging.sql  Land both raw CSVs as all-STRING tables (no type inference). {{RAW_DIR}} set by run_pipeline.py.
-- The deliveries mirror is space-padded (fixed-width style), including the header, so column names are
-- given explicitly (over -> over_no, ball -> ball_no to avoid keyword clashes). Values are trimmed in 02.
-- Databricks: read_files(..., format => 'csv', header => true, inferColumnTypes => false, schema => '<same names> STRING')
CREATE OR REPLACE TABLE stg_matches AS
SELECT * FROM read_csv('{{RAW_DIR}}/matches_2008-2024.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE stg_deliveries AS
SELECT * FROM read_csv('{{RAW_DIR}}/deliveries_2008-2024.csv', header = true, all_varchar = true,
  names = ['match_id', 'inning', 'batting_team', 'bowling_team', 'over_no', 'ball_no', 'batter', 'bowler',
           'non_striker', 'batsman_runs', 'extra_runs', 'total_runs', 'extras_type', 'is_wicket',
           'player_dismissed', 'dismissal_kind', 'fielder']);
