-- 04_analysis.sql  KPI + business-question tables (a_*). Super overs (inning > 2) excluded from player stats.

CREATE OR REPLACE TABLE a_kpi_headline AS
SELECT
  (SELECT COUNT(*) FROM fact_matches)                                         AS matches,
  (SELECT COUNT(*) FROM fact_deliveries)                                      AS deliveries,
  (SELECT COUNT(DISTINCT season) FROM fact_matches)                           AS seasons,
  (SELECT COUNT(*) FROM dim_team)                                             AS teams,
  (SELECT COUNT(*) FROM dim_venue)                                            AS venues,
  (SELECT COUNT(*) FROM dim_player)                                           AS players,
  (SELECT SUM(total_runs) FROM fact_deliveries WHERE super_over_flag = 0)     AS total_runs,
  (SELECT SUM(is_wicket) FROM fact_deliveries WHERE super_over_flag = 0)      AS total_wickets,
  (SELECT SUM(six_flag) FROM fact_deliveries WHERE super_over_flag = 0)       AS total_sixes,
  (SELECT ROUND(AVG(first_innings_runs), 1) FROM fact_matches WHERE dl_method_flag = 0 AND no_result_flag = 0) AS avg_first_innings_score,
  (SELECT ROUND(6.0 * SUM(total_runs) / SUM(legal_ball_flag), 2) FROM fact_deliveries WHERE super_over_flag = 0) AS run_rate,
  (SELECT ROUND(100.0 * SUM(toss_winner_won_flag) / COUNT(*), 2) FROM fact_matches WHERE no_result_flag = 0) AS toss_winner_win_pct,
  (SELECT ROUND(100.0 * SUM(bat_first_won_flag) / COUNT(*), 2) FROM fact_matches WHERE no_result_flag = 0) AS bat_first_win_pct,
  (SELECT ROUND(100.0 * SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0 END) / COUNT(*), 2) FROM fact_matches) AS toss_field_choice_pct;

-- Q1 team win rates (current franchise names; no-results excluded; tie decided by super over counts for winner)
CREATE OR REPLACE TABLE a_team_win_rates AS
WITH g AS (
  SELECT team1_key AS team_key, winner_key, no_result_flag, stage FROM fact_matches
  UNION ALL SELECT team2_key, winner_key, no_result_flag, stage FROM fact_matches
)
SELECT t.team_name, COUNT(*) AS matches, SUM(CASE WHEN g.winner_key = g.team_key THEN 1 ELSE 0 END) AS wins,
       SUM(g.no_result_flag) AS no_results,
       ROUND(100.0 * SUM(CASE WHEN g.winner_key = g.team_key THEN 1 ELSE 0 END) / NULLIF(SUM(1 - g.no_result_flag), 0), 2) AS win_pct,
       COALESCE(MAX(c.titles), 0) AS titles
FROM g JOIN dim_team t ON g.team_key = t.team_key
LEFT JOIN (SELECT champion, COUNT(*) AS titles FROM dim_season GROUP BY champion) c ON c.champion = t.team_name
GROUP BY t.team_name;

-- Q2 toss impact by decision and by season
CREATE OR REPLACE TABLE a_toss_impact AS
SELECT toss_decision, COUNT(*) AS matches, SUM(toss_winner_won_flag) AS toss_winner_won,
       ROUND(100.0 * SUM(toss_winner_won_flag) / COUNT(*), 2) AS toss_winner_win_pct,
       ROUND(100.0 * SUM(bat_first_won_flag) / COUNT(*), 2) AS bat_first_win_pct
FROM fact_matches WHERE no_result_flag = 0 GROUP BY toss_decision;

CREATE OR REPLACE TABLE a_season_trend AS
SELECT f.season, COUNT(*) AS matches,
       ROUND(100.0 * SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0 END) / COUNT(*), 1) AS toss_field_choice_pct,
       ROUND(100.0 * SUM(toss_winner_won_flag) / NULLIF(SUM(1 - no_result_flag), 0), 1) AS toss_winner_win_pct,
       ROUND(100.0 * SUM(bat_first_won_flag) / NULLIF(SUM(1 - no_result_flag), 0), 1) AS bat_first_win_pct,
       ROUND(AVG(CASE WHEN dl_method_flag = 0 THEN first_innings_runs END), 1) AS avg_first_innings_score,
       MAX(s.champion) AS champion
FROM fact_matches f JOIN dim_season s ON f.season = s.season
GROUP BY f.season;

-- Q3 top batters (all seasons)
CREATE OR REPLACE TABLE a_top_batters AS
WITH inn AS (
  SELECT batter_key, match_id, inning, SUM(batsman_runs) AS r FROM fact_deliveries WHERE super_over_flag = 0 GROUP BY 1, 2, 3
), ms AS (
  SELECT batter_key, COUNT(*) AS innings, SUM(CASE WHEN r BETWEEN 50 AND 99 THEN 1 ELSE 0 END) AS fifties,
         SUM(CASE WHEN r >= 100 THEN 1 ELSE 0 END) AS hundreds, MAX(r) AS high_score
  FROM inn GROUP BY batter_key
), outs AS (
  SELECT p.player_key, COUNT(*) AS dismissals
  FROM cln_deliveries d JOIN dim_player p ON d.player_dismissed = p.player_name
  WHERE d.super_over_flag = 0 AND d.dismissal_kind <> 'retired hurt' GROUP BY p.player_key
), b AS (
  SELECT batter_key, SUM(batsman_runs) AS runs, SUM(ball_faced_flag) AS balls_faced, SUM(four_flag) AS fours, SUM(six_flag) AS sixes
  FROM fact_deliveries WHERE super_over_flag = 0 GROUP BY batter_key
)
SELECT p.player_name AS batter, ms.innings, b.runs, b.balls_faced,
       ROUND(100.0 * b.runs / NULLIF(b.balls_faced, 0), 2) AS strike_rate,
       ROUND(1.0 * b.runs / NULLIF(o.dismissals, 0), 2)  AS batting_avg,
       b.fours, b.sixes, ms.fifties, ms.hundreds, ms.high_score
FROM b
JOIN ms ON b.batter_key = ms.batter_key
JOIN dim_player p ON b.batter_key = p.player_key
LEFT JOIN outs o ON b.batter_key = o.player_key
WHERE b.runs >= 1500;

-- Q4 top bowlers (wickets credited to bowler; byes / leg-byes not charged)
CREATE OR REPLACE TABLE a_top_bowlers AS
SELECT p.player_name AS bowler, COUNT(DISTINCT f.match_id) AS matches, SUM(f.bowler_wicket_flag) AS wickets,
       SUM(f.legal_ball_flag) AS legal_balls, SUM(f.bowler_runs) AS runs_conceded,
       ROUND(6.0 * SUM(f.bowler_runs) / NULLIF(SUM(f.legal_ball_flag), 0), 2) AS economy,
       ROUND(1.0 * SUM(f.bowler_runs) / NULLIF(SUM(f.bowler_wicket_flag), 0), 2) AS bowling_avg,
       ROUND(1.0 * SUM(f.legal_ball_flag) / NULLIF(SUM(f.bowler_wicket_flag), 0), 2) AS strike_rate
FROM fact_deliveries f JOIN dim_player p ON f.bowler_key = p.player_key
WHERE f.super_over_flag = 0
GROUP BY p.player_name
HAVING SUM(f.bowler_wicket_flag) >= 75;

-- Q5 venue effects (venues with >= 20 completed matches)
CREATE OR REPLACE TABLE a_venue_effects AS
SELECT v.venue, v.city, v.country, COUNT(*) AS matches,
       ROUND(AVG(CASE WHEN f.dl_method_flag = 0 THEN f.first_innings_runs END), 1) AS avg_first_innings_score,
       ROUND(100.0 * SUM(f.bat_first_won_flag) / COUNT(*), 1) AS bat_first_win_pct,
       ROUND(100.0 * SUM(f.toss_winner_won_flag) / COUNT(*), 1) AS toss_winner_win_pct,
       ROUND(100.0 * SUM(CASE WHEN f.toss_decision = 'field' THEN 1 ELSE 0 END) / COUNT(*), 1) AS toss_field_choice_pct
FROM fact_matches f JOIN dim_venue v ON f.venue_key = v.venue_key
WHERE f.no_result_flag = 0
GROUP BY v.venue, v.city, v.country
HAVING COUNT(*) >= 20;

-- Q6 scoring by phase of innings
CREATE OR REPLACE TABLE a_phase_scoring AS
SELECT phase, SUM(legal_ball_flag) AS legal_balls, SUM(total_runs) AS runs,
       ROUND(6.0 * SUM(total_runs) / SUM(legal_ball_flag), 2) AS run_rate,
       ROUND(100.0 * SUM(is_wicket) / SUM(legal_ball_flag), 2) AS wicket_pct_per_ball,
       ROUND(100.0 * SUM(four_flag + six_flag) / SUM(legal_ball_flag), 2) AS boundary_pct_per_ball
FROM fact_deliveries WHERE super_over_flag = 0 AND inning <= 2
GROUP BY phase;
