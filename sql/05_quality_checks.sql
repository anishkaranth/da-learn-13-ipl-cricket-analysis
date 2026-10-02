-- 05_quality_checks.sql  before/after counts, DQ issue counts and hard assertions

CREATE OR REPLACE TABLE dq_row_counts AS
SELECT 'matches' AS entity, (SELECT COUNT(*) FROM stg_matches) AS raw_rows,
       (SELECT COUNT(DISTINCT trim(id)) FROM stg_matches) AS distinct_keys, (SELECT COUNT(*) FROM cln_matches) AS clean_rows, 'match_id' AS grain
UNION ALL SELECT 'deliveries', (SELECT COUNT(*) FROM stg_deliveries),
       (SELECT COUNT(*) FROM (SELECT DISTINCT trim(match_id), trim(inning), trim(over_no), trim(ball_no) FROM stg_deliveries) x),
       (SELECT COUNT(*) FROM cln_deliveries), 'match_id + inning + over + ball'
UNION ALL SELECT 'fact_matches', NULL, NULL, (SELECT COUNT(*) FROM fact_matches), 'match'
UNION ALL SELECT 'fact_deliveries', NULL, NULL, (SELECT COUNT(*) FROM fact_deliveries), 'ball'
UNION ALL SELECT 'dim_team', NULL, NULL, (SELECT COUNT(*) FROM dim_team), 'franchise (current name)'
UNION ALL SELECT 'dim_venue', NULL, NULL, (SELECT COUNT(*) FROM dim_venue), 'canonical venue'
UNION ALL SELECT 'dim_player', NULL, NULL, (SELECT COUNT(*) FROM dim_player), 'player name'
UNION ALL SELECT 'dim_season', NULL, NULL, (SELECT COUNT(*) FROM dim_season), 'season';

CREATE OR REPLACE TABLE dq_issues AS
SELECT 'matches: distinct raw venue strings' AS check_name, (SELECT COUNT(DISTINCT trim(venue)) FROM stg_matches) AS affected_rows
UNION ALL SELECT 'matches: canonical venues after standardisation', (SELECT COUNT(*) FROM dim_venue)
UNION ALL SELECT 'matches: raw team names', (SELECT COUNT(*) FROM (SELECT trim(team1) t FROM stg_matches UNION SELECT trim(team2) FROM stg_matches) x)
UNION ALL SELECT 'matches: franchises after rename mapping', (SELECT COUNT(*) FROM dim_team)
UNION ALL SELECT 'matches: city NA (filled from venue)', (SELECT COUNT(*) FROM stg_matches WHERE trim(city) = 'NA')
UNION ALL SELECT 'matches: no result (winner NA)', (SELECT SUM(no_result_flag) FROM cln_matches)
UNION ALL SELECT 'matches: tie decided by super over', (SELECT SUM(super_over_flag) FROM cln_matches)
UNION ALL SELECT 'matches: D/L method', (SELECT SUM(dl_method_flag) FROM cln_matches)
UNION ALL SELECT 'deliveries: header + values space-padded', (SELECT COUNT(*) FROM stg_deliveries WHERE batter <> trim(batter))
UNION ALL SELECT 'deliveries: duplicate ball keys dropped', (SELECT COUNT(*) FROM stg_deliveries) - (SELECT COUNT(*) FROM cln_deliveries)
UNION ALL SELECT 'deliveries: super-over balls (excluded from player stats)', (SELECT SUM(super_over_flag) FROM cln_deliveries)
UNION ALL SELECT 'deliveries: wides + no-balls', (SELECT COUNT(*) FROM cln_deliveries WHERE legal_ball_flag = 0)
UNION ALL SELECT 'deliveries: runs outlier (>7 on a ball)', (SELECT SUM(dq_runs_outlier) FROM cln_deliveries)
UNION ALL SELECT 'deliveries: batsman+extra <> total', (SELECT SUM(dq_runs_mismatch) FROM cln_deliveries);

CREATE OR REPLACE TABLE dq_assertions AS
WITH c AS (
  SELECT 'fact_matches.match_id unique' AS check_name, (SELECT COUNT(*) - COUNT(DISTINCT match_id) FROM fact_matches) AS failed_rows
  UNION ALL SELECT 'every clean match is in fact_matches', (SELECT COUNT(*) FROM cln_matches) - (SELECT COUNT(*) FROM fact_matches)
  UNION ALL SELECT 'every clean delivery is in fact_deliveries', (SELECT COUNT(*) FROM cln_deliveries) - (SELECT COUNT(*) FROM fact_deliveries)
  UNION ALL SELECT 'delivery key unique', (SELECT COUNT(*) FROM (SELECT match_id, inning, over_no, ball_no FROM fact_deliveries GROUP BY 1, 2, 3, 4 HAVING COUNT(*) > 1) x)
  UNION ALL SELECT 'winner is one of the two teams', (SELECT COUNT(*) FROM fact_matches WHERE winner_key IS NOT NULL AND winner_key NOT IN (team1_key, team2_key))
  UNION ALL SELECT 'toss winner is one of the two teams', (SELECT COUNT(*) FROM fact_matches WHERE toss_winner_key NOT IN (team1_key, team2_key))
  UNION ALL SELECT 'batting team <> bowling team', (SELECT COUNT(*) FROM fact_deliveries WHERE batting_team_key = bowling_team_key)
  UNION ALL SELECT 'over_no in 0..19', (SELECT COUNT(*) FROM fact_deliveries WHERE over_no NOT BETWEEN 0 AND 19)
  UNION ALL SELECT 'total_runs >= 0', (SELECT COUNT(*) FROM fact_deliveries WHERE total_runs < 0)
  UNION ALL SELECT 'every season has one champion', (SELECT COUNT(*) FROM dim_season WHERE champion IS NULL)
  UNION ALL SELECT 'runs reconcile: deliveries vs innings totals',
    (SELECT ABS((SELECT SUM(total_runs) FROM fact_deliveries WHERE inning IN (1, 2)) -
                (SELECT SUM(COALESCE(first_innings_runs, 0) + COALESCE(second_innings_runs, 0)) FROM fact_matches)))
)
SELECT check_name, failed_rows, CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status FROM c;
