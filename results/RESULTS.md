# Results: IPL 2008–2024 (full data)

All numbers come from `python run_pipeline.py --source full` on DuckDB over 1,095 matches and 260,920 deliveries. Databricks reproduced them with 0 differences.

## KPIs
| Metric | Value |
|---|---|
| Matches / seasons | 1,095 / 17 |
| Deliveries (incl. 161 super-over balls) | 260,920 |
| Franchises / venues / players | 15 / 36 / 732 |
| Runs / wickets / sixes | 347,470 / 12,923 / 13,036 |
| Run rate (runs per over) | 8.30 |
| Avg first-innings score | 166.1 |
| Toss winner wins | 50.83% |
| Bat-first side wins | 45.87% |
| Toss winners choosing to field | 64.29% |

## Toss impact
| Toss decision | Matches | Toss winner won | Win % |
|---|---|---|---|
| field | 700 | 377 | 53.86% |
| bat | 390 | 177 | 45.38% |

Field-first choice peaked at 83.3% in 2018–19.

## Team win rates (franchises with at least 40 matches)
Gujarat Titans 62.2% (45 matches), Chennai Super Kings 58.2% (138/238, 5 titles), Lucknow Super Giants 55.8%, Mumbai Indians 55.2% (5 titles), Kolkata Knight Riders 52.2%, Rajasthan Royals 51.1%, Royal Challengers Bengaluru 48.8%, Sunrisers Hyderabad 48.4%, Delhi Capitals 46.0%, Punjab Kings 45.5%, Deccan Chargers 38.7%, Pune Warriors 26.7%.

## Scoring trend
Average first-innings score: 150.3 in 2009, 182.2 in 2023, and 189.6 in 2024, the highest of any season.

## Phase of innings
| Phase | Run rate | Wicket per legal ball |
|---|---|---|
| Powerplay (1–6) | 7.85 | 3.99% |
| Middle (7–15) | 7.79 | – |
| Death (16–20) | 9.96 | 8.46% |

## Batters and bowlers
- **Runs:** Kohli 8,004 (SR 131.97, average 38.67, 8 hundreds), Dhawan 6,769, Rohit Sharma 6,628, Warner 6,565, Raina 5,528.
- **Strike rate (at least 1,500 runs):** Russell 174.93.
- **Wickets:** Chahal 205 (economy 7.84), Chawla 192, Bravo 183, Bhuvneshwar 181, Narine 180 (economy 6.73), Ashwin 180.

## Venues (at least 20 matches)
- **Bat-first win %:** MA Chidambaram 57.6% (the highest), Maharashtra CA 54.9%, Dubai 50.0%, Arun Jaitley 48.3%, Wankhede 45.8%, Chinnaswamy 45.1%, Eden Gardens 40.9%, Sawai Mansingh 35.1% (the lowest).
- **Chinnaswamy:** captains chose to field 90.1% of the time, and the average first-innings score is 175.0.

## Data quality
- 14 ties decided by super over, 21 D/L matches and 5 no-results, all flagged.
- 51 missing `city` values were filled from the venue.
- 9,449 wides and no-balls are marked as not legal deliveries.
- 161 super-over balls are excluded from player stats.
- 11/11 assertions pass: unique keys, foreign-key integrity, runs reconciled between deliveries and matches, and non-negative runs.

## Charts
`charts/dashboard.svg`, `team_win_rates.svg`, `season_scoring.svg`, `toss_impact.svg`, `top_batters.svg`, `top_bowlers.svg`, `venue_effects.svg` (vector SVG only).
