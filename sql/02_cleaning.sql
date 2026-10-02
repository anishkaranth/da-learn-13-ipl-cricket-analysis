-- 02_cleaning.sql  (Spark SQL dialect; DuckDB via 00 shims)
-- trim padding -> 'NA'/'' to NULL -> TRY_CAST types -> standardise franchise + venue names
-- -> dedupe on natural keys -> derived flags (super over, legal ball, phase) -> integrity filters.

-- Franchise renames are mapped to the current name so a club's history is continuous.
CREATE OR REPLACE TABLE map_team AS
SELECT * FROM (VALUES
  ('Delhi Daredevils', 'Delhi Capitals'),
  ('Kings XI Punjab', 'Punjab Kings'),
  ('Royal Challengers Bangalore', 'Royal Challengers Bengaluru'),
  ('Rising Pune Supergiants', 'Rising Pune Supergiant')
) AS t(raw_name, team_name);

CREATE OR REPLACE TABLE cln_matches AS
WITH typed AS (
  SELECT
    TRY_CAST(trim(id) AS BIGINT)                                   AS match_id,
    TRY_CAST(substr(trim(season), 1, 4) AS INT)                    AS season,
    to_date(trim(date))                                          AS match_date,
    NULLIF(NULLIF(trim(city), 'NA'), '')                           AS city_raw,
    trim(venue)                                                    AS venue_raw,
    trim(match_type)                                               AS match_type,
    NULLIF(NULLIF(trim(player_of_match), 'NA'), '')                AS player_of_match,
    trim(team1) AS team1_raw, trim(team2) AS team2_raw,
    trim(toss_winner) AS toss_winner_raw,
    lower(trim(toss_decision))                                     AS toss_decision,
    NULLIF(NULLIF(trim(winner), 'NA'), '')                         AS winner_raw,
    lower(trim(result))                                            AS result,
    TRY_CAST(NULLIF(trim(result_margin), 'NA') AS INT)             AS result_margin,
    TRY_CAST(NULLIF(trim(target_runs), 'NA') AS INT)               AS target_runs,
    TRY_CAST(NULLIF(trim(target_overs), 'NA') AS DOUBLE)           AS target_overs,
    CASE WHEN upper(trim(super_over)) = 'Y' THEN 1 ELSE 0 END      AS super_over_flag,
    CASE WHEN trim(method) = 'D/L' THEN 1 ELSE 0 END               AS dl_method_flag
  FROM stg_matches
), venue_std AS (
  SELECT *,
    -- canonical venue: text before the first comma, dots removed, historical names mapped to current
    trim(replace(replace(split_part(venue_raw, ',', 1), '.', ' '), '  ', ' ')) AS v0
  FROM typed
), ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY match_date) AS rn FROM venue_std WHERE match_id IS NOT NULL
)
SELECT
  r.match_id, r.season, r.match_date, r.match_type,
  CASE WHEN r.match_type = 'League' THEN 'League' ELSE 'Playoff' END                     AS stage,
  CASE r.v0
    WHEN 'Feroz Shah Kotla' THEN 'Arun Jaitley Stadium'
    WHEN 'Punjab Cricket Association Stadium' THEN 'Punjab Cricket Association IS Bindra Stadium'
    WHEN 'Sardar Patel Stadium' THEN 'Narendra Modi Stadium'
    WHEN 'Sheikh Zayed Stadium' THEN 'Zayed Cricket Stadium'
    WHEN 'Subrata Roy Sahara Stadium' THEN 'Maharashtra Cricket Association Stadium'
    ELSE r.v0 END                                                                        AS venue,
  r.venue_raw,
  CASE WHEN r.city_raw = 'Bangalore' THEN 'Bengaluru'
       WHEN r.city_raw IS NOT NULL THEN r.city_raw
       WHEN r.venue_raw LIKE '%Dubai%' THEN 'Dubai'
       WHEN r.venue_raw LIKE '%Sharjah%' THEN 'Sharjah'
       ELSE NULL END                                                                     AS city,
  COALESCE(t1.team_name, r.team1_raw)  AS team1,
  COALESCE(t2.team_name, r.team2_raw)  AS team2,
  COALESCE(tw.team_name, r.toss_winner_raw) AS toss_winner,
  r.toss_decision,
  COALESCE(w.team_name, r.winner_raw)  AS winner,
  r.result, r.result_margin, r.target_runs, r.target_overs, r.super_over_flag, r.dl_method_flag,
  r.player_of_match,
  -- who batted first (toss winner chooses)
  CASE WHEN r.toss_decision = 'bat' THEN COALESCE(tw.team_name, r.toss_winner_raw)
       WHEN COALESCE(tw.team_name, r.toss_winner_raw) = COALESCE(t1.team_name, r.team1_raw) THEN COALESCE(t2.team_name, r.team2_raw)
       ELSE COALESCE(t1.team_name, r.team1_raw) END                                      AS bat_first_team,
  CASE WHEN r.winner_raw IS NULL THEN 1 ELSE 0 END                                       AS no_result_flag,
  CASE WHEN r.winner_raw IS NOT NULL AND r.winner_raw = r.toss_winner_raw THEN 1 ELSE 0 END AS toss_winner_won_flag,
  CASE WHEN r.venue_raw <> r.v0 THEN 1 ELSE 0 END                                        AS dq_venue_renamed
FROM ranked r
LEFT JOIN map_team t1 ON r.team1_raw = t1.raw_name
LEFT JOIN map_team t2 ON r.team2_raw = t2.raw_name
LEFT JOIN map_team tw ON r.toss_winner_raw = tw.raw_name
LEFT JOIN map_team w  ON r.winner_raw = w.raw_name
WHERE r.rn = 1 AND r.season IS NOT NULL AND r.match_date IS NOT NULL
  AND r.toss_decision IN ('bat', 'field');

CREATE OR REPLACE TABLE cln_deliveries AS
WITH typed AS (
  SELECT
    TRY_CAST(trim(match_id) AS BIGINT)                AS match_id,
    TRY_CAST(trim(inning) AS INT)                     AS inning,
    trim(batting_team)                                AS batting_team_raw,
    trim(bowling_team)                                AS bowling_team_raw,
    TRY_CAST(trim(over_no) AS INT)                    AS over_no,
    TRY_CAST(trim(ball_no) AS INT)                    AS ball_no,
    trim(batter) AS batter, trim(bowler) AS bowler, trim(non_striker) AS non_striker,
    TRY_CAST(trim(batsman_runs) AS INT)               AS batsman_runs,
    TRY_CAST(trim(extra_runs) AS INT)                 AS extra_runs,
    TRY_CAST(trim(total_runs) AS INT)                 AS total_runs,
    NULLIF(NULLIF(lower(trim(extras_type)), 'na'), '') AS extras_type,
    TRY_CAST(trim(is_wicket) AS INT)                  AS is_wicket,
    NULLIF(NULLIF(trim(player_dismissed), 'NA'), '')  AS player_dismissed,
    NULLIF(NULLIF(lower(trim(dismissal_kind)), 'na'), '') AS dismissal_kind,
    NULLIF(NULLIF(trim(fielder), 'NA'), '')           AS fielder
  FROM stg_deliveries
), ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY match_id, inning, over_no, ball_no ORDER BY total_runs DESC) AS rn
  FROM typed
)
SELECT
  d.match_id, d.inning, d.over_no, d.ball_no,
  COALESCE(bt.team_name, d.batting_team_raw) AS batting_team,
  COALESCE(bw.team_name, d.bowling_team_raw) AS bowling_team,
  d.batter, d.bowler, d.non_striker,
  d.batsman_runs, d.extra_runs, d.total_runs, d.extras_type, d.is_wicket,
  d.player_dismissed, d.dismissal_kind, d.fielder,
  CASE WHEN d.inning > 2 THEN 1 ELSE 0 END                                         AS super_over_flag,
  CASE WHEN COALESCE(d.extras_type, '') = 'wides' THEN 0 ELSE 1 END                AS ball_faced_flag,
  CASE WHEN COALESCE(d.extras_type, '') IN ('wides', 'noballs') THEN 0 ELSE 1 END  AS legal_ball_flag,
  d.total_runs - CASE WHEN COALESCE(d.extras_type, '') IN ('byes', 'legbyes', 'penalty') THEN d.extra_runs ELSE 0 END AS bowler_runs,
  CASE WHEN d.dismissal_kind IN ('bowled', 'caught', 'lbw', 'stumped', 'caught and bowled', 'hit wicket') THEN 1 ELSE 0 END AS bowler_wicket_flag,
  CASE WHEN d.batsman_runs = 4 THEN 1 ELSE 0 END AS four_flag,
  CASE WHEN d.batsman_runs = 6 THEN 1 ELSE 0 END AS six_flag,
  CASE WHEN d.over_no < 6 THEN '1 Powerplay (1-6)' WHEN d.over_no < 15 THEN '2 Middle (7-15)' ELSE '3 Death (16-20)' END AS phase,
  CASE WHEN d.total_runs > 7 OR d.batsman_runs NOT IN (0, 1, 2, 3, 4, 5, 6) THEN 1 ELSE 0 END AS dq_runs_outlier,
  CASE WHEN d.batsman_runs + d.extra_runs <> d.total_runs THEN 1 ELSE 0 END AS dq_runs_mismatch
FROM ranked d
LEFT JOIN map_team bt ON d.batting_team_raw = bt.raw_name
LEFT JOIN map_team bw ON d.bowling_team_raw = bw.raw_name
WHERE d.rn = 1 AND d.match_id IS NOT NULL AND d.inning IS NOT NULL AND d.over_no BETWEEN 0 AND 19
  AND d.total_runs IS NOT NULL
  AND d.match_id IN (SELECT match_id FROM cln_matches);
