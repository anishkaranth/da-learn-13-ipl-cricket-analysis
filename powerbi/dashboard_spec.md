# Dashboard spec: IPL cricket analysis

**Page 1 · Overview.** Slicers: season, team.
- Cards: Matches, Run Rate, Avg First Innings Score, Toss Winner Win %, Bat First Win %
- Clustered bar: Team Win % by dim_team[team_name], sorted descending, with Team Matches ≥ 40 as a visual-level filter
- Line: Avg First Innings Score by dim_season[season]
- Column: Toss Winner Win % by fact_matches[toss_decision]

**Page 2 · Players.**
- Bar: Batter Runs by Batter[player_name], Top N = 10, with Strike Rate in the tooltip
- Bar: Bowler Wickets by Bowler[player_name], Top N = 10, with Economy in the tooltip
- Column: Run Rate and Wicket % per Ball by fact_deliveries[phase]

**Page 3 · Venues.**
- Bar: Bat First Win % by dim_venue[venue] (Matches ≥ 20)
- Table: venue, Matches, Field Choice %, Avg First Innings Score

Expected values on the full data, to sanity-check your build: Toss Winner Win % 50.83%, Bat First Win % 45.87%, Run Rate 8.30, CSK Team Win % 58.23%, Kohli 8,004 runs, Chahal 205 wickets.
