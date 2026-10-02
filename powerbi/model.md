# Power BI model (star schema)

| Table | Grain | Key | Sample rows in data/ |
|---|---|---|---|
| fact_matches | one match | match_id | 71 (2024 season) |
| fact_deliveries | one ball | match_id+inning+over_no+ball_no | 60 (2024 final) |
| dim_team | franchise (current name) | team_key | 15 |
| dim_venue | venue (standardised) | venue_key | 36 |
| dim_player | batter / bowler | player_key | 209 (players appearing in 2024) |
| dim_season | season | season | 17 |

## Relationships (single direction, dim → fact)
- dim_season[season] 1→* fact_matches[season], and 1→* fact_deliveries[season]
- dim_venue[venue_key] 1→* fact_matches[venue_key]
- fact_matches[match_id] 1→* fact_deliveries[match_id]
- dim_team[team_key] → fact_deliveries[batting_team_key] (active), and → bowling_team_key (inactive)
- dim_team[team_key] → fact_matches[team1_key] (active). team2_key, winner_key, toss_winner_key and bat_first_team_key are **inactive** and are used through `USERELATIONSHIP` in the measures.
- dim_player is loaded twice, as **Batter** (→ batter_key) and **Bowler** (→ bowler_key), to avoid ambiguous paths.

## Notes
- Flags are 0/1 integers, so SUM gives counts.
- `phase` takes the values `1 Powerplay (1-6)`, `2 Middle (7-15)` and `3 Death (16-20)`. The numeric prefix makes them sort alphabetically.
- The CSVs here are sample-sized. For the full model, run `python run_pipeline.py --source full` and point Power BI at `data/clean_full/` instead.
