"""Project config shared by run_pipeline.py, build_databricks.py (and the Databricks deploy)."""
REPO = "da-learn-13-ipl-cricket-analysis"
NN = "13"
DASH_TITLE = "IPL cricket analysis 2008-2024"
DASH_NAME = "da-learn-13 IPL cricket analysis"
NOTEBOOK = "ipl_pipeline_notebook"
DASH_FILE = "ipl_cricket_dashboard"
CURRENCY = "INR"
DATASET = "IPL Complete Dataset 2008-2024 (Kaggle patrickb1912/ipl-complete-dataset-20082020; GitHub mirror avinashyadav16/ipl-analytics)"
DELIVERY_COLS = ["match_id", "inning", "batting_team", "bowling_team", "over_no", "ball_no", "batter", "bowler",
                 "non_striker", "batsman_runs", "extra_runs", "total_runs", "extras_type", "is_wicket",
                 "player_dismissed", "dismissal_kind", "fielder"]
RAW = {"stg_matches": {"file": "matches_2008-2024.csv", "format": "csv"},
       "stg_deliveries": {"file": "deliveries_2008-2024.csv", "format": "csv", "columns": DELIVERY_COLS}}
RAW_FILES = [v["file"] for v in RAW.values()]
CLEAN = ["cln_matches", "cln_deliveries"]
STAR = ["fact_matches", "fact_deliveries", "dim_team", "dim_venue", "dim_player", "dim_season"]
# Power BI kit: sample-sized star (2024 season matches, 2024 final ball-by-ball, players of 2024)
PBI_CAP = {"fact_matches": 100, "fact_deliveries": 150, "dim_player": 400}
PBI_SAMPLE_FILTER = {"fact_matches": "season = 2024",
                     "fact_deliveries": "match_id = (SELECT MAX(match_id) FROM fact_matches WHERE match_type = 'Final')",
                     "dim_player": "player_key IN (SELECT batter_key FROM fact_deliveries WHERE season = 2024 UNION SELECT bowler_key FROM fact_deliveries WHERE season = 2024)"}
COMPARE_TABLES = ["a_team_win_rates", "a_toss_impact", "a_top_batters", "a_top_bowlers", "a_venue_effects", "a_phase_scoring", "dq_issues"]
SHOT_CONFIG = {"engine": "duckdb (local, full data) + Databricks serverless SQL", "sql_dialect": "Spark/Databricks SQL + DuckDB shims (sql/00)",
               "team_names": "franchise renames mapped to current name", "player_stats": "super overs excluded",
               "bowler_wickets": "bowled, caught, lbw, stumped, caught and bowled, hit wicket",
               "sample_rule": "data/raw = 2024 Final (match row + its deliveries)"}
SHOT_QUERIES = {
    "top5_win_pct": "SELECT team_name, matches, wins, win_pct, titles FROM a_team_win_rates WHERE matches >= 100 ORDER BY win_pct DESC LIMIT 5",
    "toss_impact": "SELECT * FROM a_toss_impact ORDER BY toss_decision",
    "top5_batters": "SELECT batter, runs, strike_rate, batting_avg FROM a_top_batters ORDER BY runs DESC LIMIT 5",
    "top5_bowlers": "SELECT bowler, wickets, economy, bowling_avg FROM a_top_bowlers ORDER BY wickets DESC LIMIT 5",
    "phase_scoring": "SELECT phase, run_rate, wicket_pct_per_ball FROM a_phase_scoring ORDER BY phase",
}
METRIC_QUERIES = {
    "team_win_rates": "SELECT * FROM a_team_win_rates ORDER BY win_pct DESC",
    "toss_impact": "SELECT * FROM a_toss_impact ORDER BY toss_decision",
    "season_trend": "SELECT * FROM a_season_trend ORDER BY season",
    "top10_batters": "SELECT * FROM a_top_batters ORDER BY runs DESC LIMIT 10",
    "top10_bowlers": "SELECT * FROM a_top_bowlers ORDER BY wickets DESC LIMIT 10",
    "venue_effects": "SELECT * FROM a_venue_effects ORDER BY matches DESC",
    "phase_scoring": "SELECT * FROM a_phase_scoring ORDER BY phase",
}
CARDS = [("matches", "Matches", "{:,}"), ("deliveries", "Deliveries", "{:,}"), ("total_runs", "Runs", "{:,}"),
         ("run_rate", "Run rate", "{:.2f}"), ("avg_first_innings_score", "Avg 1st-inn score", "{:.1f}"),
         ("toss_winner_win_pct", "Toss winner wins", "{:.1f}%"), ("bat_first_win_pct", "Bat-first wins", "{:.1f}%")]
DASH_KPI_SQL = "SELECT matches, deliveries, toss_winner_win_pct / 100 AS toss_winner_win_rate, bat_first_win_pct / 100 AS bat_first_win_rate FROM {S}a_kpi_headline"
COUNTERS = [("matches", "Matches 2008-2024", "num"), ("toss_winner_win_rate", "Toss winner win rate", "pct")]
DASH_NOTE = "Source: IPL Complete Dataset 2008-2024 (Kaggle). Team names mapped to current franchise. Tables: workspace.da_learn_13."
VIZ = [
    {"name": "team_win_rates", "title": "Win % by franchise (>= 40 matches)", "kind": "hbar", "x": "team_name", "y": "win_pct", "fmt": "{:.1f}%",
     "sql": "SELECT team_name, win_pct FROM {S}a_team_win_rates WHERE matches >= 40 ORDER BY win_pct DESC"},
    {"name": "season_scoring", "title": "Average first-innings score by season", "kind": "line", "x": "season", "y": "avg_first_innings_score", "fmt": "{:.0f}",
     "sql": "SELECT season, avg_first_innings_score FROM {S}a_season_trend ORDER BY season"},
    {"name": "toss_impact", "title": "Toss winner win % by toss decision", "kind": "bar", "x": "toss_decision", "y": "toss_winner_win_pct", "fmt": "{:.1f}%",
     "sql": "SELECT toss_decision, toss_winner_win_pct FROM {S}a_toss_impact ORDER BY toss_decision"},
    {"name": "top_batters", "title": "Top 10 run scorers", "kind": "hbar", "x": "batter", "y": "runs", "fmt": "{:,.0f}",
     "sql": "SELECT batter, runs FROM {S}a_top_batters ORDER BY runs DESC LIMIT 10"},
    {"name": "top_bowlers", "title": "Top 10 wicket takers", "kind": "hbar", "x": "bowler", "y": "wickets", "fmt": "{:,.0f}",
     "sql": "SELECT bowler, wickets FROM {S}a_top_bowlers ORDER BY wickets DESC LIMIT 10"},
    {"name": "venue_effects", "title": "Bat-first win % by venue (>= 20 matches)", "kind": "hbar", "x": "venue", "y": "bat_first_win_pct", "fmt": "{:.1f}%",
     "sql": "SELECT venue, bat_first_win_pct FROM {S}a_venue_effects ORDER BY matches DESC LIMIT 10"},
]
