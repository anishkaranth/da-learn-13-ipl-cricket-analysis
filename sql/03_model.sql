-- 03_model.sql  Star schema: fact_deliveries (ball grain) + fact_matches (match grain)
-- dims: dim_team, dim_venue, dim_player, dim_season. Surrogate keys via ROW_NUMBER over the natural key.

CREATE OR REPLACE TABLE dim_team AS
SELECT ROW_NUMBER() OVER (ORDER BY team_name) AS team_key, team_name,
       CASE WHEN team_name IN ('Chennai Super Kings', 'Delhi Capitals', 'Gujarat Titans', 'Kolkata Knight Riders',
            'Lucknow Super Giants', 'Mumbai Indians', 'Punjab Kings', 'Rajasthan Royals',
            'Royal Challengers Bengaluru', 'Sunrisers Hyderabad') THEN 1 ELSE 0 END AS is_active_2024
FROM (SELECT team1 AS team_name FROM cln_matches UNION SELECT team2 FROM cln_matches) t;

CREATE OR REPLACE TABLE dim_venue AS
SELECT ROW_NUMBER() OVER (ORDER BY venue) AS venue_key, venue, city, country
FROM (
  SELECT venue, MAX(city) AS city,
         CASE WHEN MAX(city) IN ('Dubai', 'Sharjah', 'Abu Dhabi') THEN 'UAE'
              WHEN MAX(city) IN ('Cape Town', 'Port Elizabeth', 'Durban', 'Centurion', 'Johannesburg', 'Kimberley', 'Bloemfontein', 'East London') THEN 'South Africa'
              ELSE 'India' END AS country
  FROM cln_matches GROUP BY venue
) v;

CREATE OR REPLACE TABLE dim_player AS
SELECT ROW_NUMBER() OVER (ORDER BY player_name) AS player_key, player_name
FROM (SELECT batter AS player_name FROM cln_deliveries UNION SELECT bowler FROM cln_deliveries
      UNION SELECT non_striker FROM cln_deliveries) p;

CREATE OR REPLACE TABLE dim_season AS
SELECT season, MIN(match_date) AS first_match, MAX(match_date) AS last_match, COUNT(*) AS matches,
       MAX(CASE WHEN match_type = 'Final' THEN winner END) AS champion
FROM cln_matches GROUP BY season;

CREATE OR REPLACE TABLE fact_matches AS
SELECT m.match_id, m.season, m.match_date, m.stage, m.match_type, v.venue_key,
       t1.team_key AS team1_key, t2.team_key AS team2_key, tw.team_key AS toss_winner_key,
       w.team_key AS winner_key, bf.team_key AS bat_first_team_key,
       m.toss_decision, m.result, m.result_margin, m.target_runs, m.super_over_flag, m.dl_method_flag,
       m.no_result_flag, m.toss_winner_won_flag,
       CASE WHEN m.no_result_flag = 0 AND m.winner = m.bat_first_team THEN 1 ELSE 0 END AS bat_first_won_flag,
       s1.runs AS first_innings_runs, s1.wkts AS first_innings_wkts,
       s2.runs AS second_innings_runs, s2.wkts AS second_innings_wkts
FROM cln_matches m
JOIN dim_venue v ON m.venue = v.venue
JOIN dim_team t1 ON m.team1 = t1.team_name
JOIN dim_team t2 ON m.team2 = t2.team_name
JOIN dim_team tw ON m.toss_winner = tw.team_name
LEFT JOIN dim_team w ON m.winner = w.team_name
LEFT JOIN dim_team bf ON m.bat_first_team = bf.team_name
LEFT JOIN (SELECT match_id, SUM(total_runs) AS runs, SUM(is_wicket) AS wkts FROM cln_deliveries WHERE inning = 1 GROUP BY match_id) s1 ON m.match_id = s1.match_id
LEFT JOIN (SELECT match_id, SUM(total_runs) AS runs, SUM(is_wicket) AS wkts FROM cln_deliveries WHERE inning = 2 GROUP BY match_id) s2 ON m.match_id = s2.match_id;

CREATE OR REPLACE TABLE fact_deliveries AS
SELECT d.match_id, d.inning, d.over_no, d.ball_no, m.season,
       bt.team_key AS batting_team_key, bw.team_key AS bowling_team_key,
       pb.player_key AS batter_key, pw.player_key AS bowler_key,
       d.batsman_runs, d.extra_runs, d.total_runs, d.bowler_runs, d.extras_type, d.is_wicket, d.dismissal_kind,
       d.bowler_wicket_flag, d.ball_faced_flag, d.legal_ball_flag, d.four_flag, d.six_flag, d.phase, d.super_over_flag
FROM cln_deliveries d
JOIN cln_matches m ON d.match_id = m.match_id
JOIN dim_team bt ON d.batting_team = bt.team_name
JOIN dim_team bw ON d.bowling_team = bw.team_name
JOIN dim_player pb ON d.batter = pb.player_name
JOIN dim_player pw ON d.bowler = pw.player_name;
