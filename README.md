# NBA Finals 2026: Knicks vs. Spurs — a SQL analysis

The New York Knicks beat the San Antonio Spurs **4–1** in the 2025–26 NBA Finals
(June 3–13 2026). This project takes the raw box-score data for that series, models it into a
normalized PostgreSQL schema, and uses SQL to work through two questions:

1. **Why did the Knicks win?** — was it their top-heavy star core, or their depth?
2. **Who rose to the occasion, and who fell short of their regular-season form?**

Everything below comes from queries in [`queries/`](queries/); the numbers are query output,
and each section notes what the data does and doesn't support.

---

## Dataset

[**Historical NBA Data and Player Box Scores**](https://www.kaggle.com/datasets/eoinamoore/historical-nba-data-and-player-box-scores)
(Kaggle, eoinamoore) — historical NBA data covering games through the 2025–26 season. Raw files
used (not committed — see [`.gitignore`](.gitignore)):

| File | Contents |
|---|---|
| `PlayerStatisticsExtended.csv` | Per-player, per-game box scores |
| `TeamStatisticsExtended.csv` | Per-team, per-game box scores |
| `raw_games.csv` | Game metadata (date, teams, score, game type, series label) |
| `TeamHistories.csv` | Franchise history / team identifiers |

## Repository structure

```
sql-knicks-project/
├── scripts/
│   ├── create_tables.sql        # staging + normalized schema
│   ├── import_data.sql          # notes on loading the raw CSVs
│   ├── table_manipulation.sql   # staging -> normalized transforms, column additions
│   └── views.sql                # player_game_total, team_game_total helper views
├── queries/
│   ├── question1_star_vs_depth.sql
│   ├── question1b_hidden_heroes.sql
│   └── question2_playoff_pressure_or_pop_off.sql
└── data/                        # raw CSVs (git-ignored)
```

## How the database is built

1. **Schema** — `create_tables.sql` creates staging tables (`raw_teams`, `raw_team_stats`,
   `raw_player_stats`, `rawgames`) and the normalized model: `teams`, `players`, `player_teams`
   (players can change teams mid-season), `games`, `player_stats`, `team_stats`.
2. **Load** — the four raw CSVs are imported into the staging tables (via the DBeaver import
   wizard / `\copy`).
3. **Transform** — `table_manipulation.sql` filters to current NBA teams and the 2025–26 season,
   re-assigns clean surrogate keys, adds the box-score columns of interest
   (`fgs_made`, `three_pts_attempted`, `usage_pct`, …), and populates the normalized tables.
4. **Views** — `views.sql` builds `player_game_total` and `team_game_total`, which flatten
   player/team + game + opponent into one row so the analysis queries can filter by
   `game_type` and opponent directly.

**Series scope:** the 5 Finals games (`game_id 42500401`–`42500405`, `gameLabel = 'NBA Finals'`)
where both teams are the Knicks (`team_id 20`) or Spurs (`team_id 27`).
Final scores: NYK 105–95, 105–104, 111–115, 107–106, 94–90.

---

# Question 1 — Why did the Knicks win?

Two angles: how concentrated each team's production was (**1a**), and what the bench added
(**1b**).

## 1a — Star concentration vs. balance

`queries/question1_star_vs_depth.sql` builds the `pt_share` view: each player's share of their
team's Finals scoring, plus a PRA (points + rebounds + assists) share.

### Share of team scoring

| Team | Player | Pts | Team pts | Point share | Scoring rank |
|---|---|--:|--:|--:|--:|
| NYK | Jalen Brunson | 163 | 522 | **0.31** | 1 |
| NYK | OG Anunoby | 106 | 522 | 0.20 | 2 |
| NYK | Karl-Anthony Towns | 65 | 522 | 0.12 | 3 |
| NYK | Mikal Bridges | 52 | 522 | 0.10 | 4 |
| NYK | Josh Hart | 38 | 522 | 0.07 | 5 |
| SAS | Victor Wembanyama | 130 | 510 | 0.25 | 1 |
| SAS | Dylan Harper | 90 | 510 | 0.18 | 2 |
| SAS | Stephon Castle | 73 | 510 | 0.14 | 3 |
| SAS | De'Aaron Fox | 64 | 510 | 0.13 | 4 |
| SAS | Devin Vassell | 64 | 510 | 0.13 | 4 |
| SAS | Julian Champagnie | 55 | 510 | 0.11 | 6 |

### Top-3 combined share

| Team | Top-3 point share | Top-3 PRA share (leader → 3rd) |
|---|--:|--:|
| NYK | **0.63** | 0.24 → 0.16 → 0.15 |
| SAS | 0.57 | 0.24 → 0.16 → 0.14 |

**What the data shows:** the Knicks' production was the *more* concentrated of the two.
Brunson alone took 31% of their Finals scoring, and their top three combined for 63% of points
versus 57% for San Antonio. The Spurs' scoring curve is flatter — five players between 13% and
25% — and their PRA contribution stays meaningful roughly six players deep, where the Knicks'
tails off after three. In this series the more top-heavy team won; with a single five-game
sample that's an observation, not a causal claim.

## 1b — Hidden heroes: bench contribution

`queries/question1b_hidden_heroes.sql` builds the `bench` view — players ranked outside the top
5 in total Finals minutes on their team (`minutes_rank > 5`).

### Bench plus/minus

| Team | Player | Min rank | Avg +/- | Min | Max |
|---|---|--:|--:|--:|--:|
| NYK | Jose Alvarado | 9 | **+4.0** | -11 | 11 |
| NYK | Jordan Clarkson | 10 | +3.8 | 2 | 8 |
| NYK | Ariel Hukporti | 11 | +3.5 | 3 | 4 |
| NYK | Miles McBride | 8 | +0.2 | -14 | 11 |
| NYK | Mitchell Robinson | 7 | -7.2 | -14 | 5 |
| NYK | Landry Shamet | 6 | -9.6 | -20 | 9 |
| SAS | Keldon Johnson | 7 | **+5.2** | -5 | 17 |
| SAS | Dylan Harper | 6 | -0.2 | -12 | 12 |
| SAS | Carter Bryant | 9 | -1.0 | -9 | 6 |
| SAS | Harrison Barnes | 10 | -3.5 | -5 | -2 |
| SAS | Luke Kornet | 8 | -4.4 | -7 | -2 |

### Scoring rate and ball security

| Team | Player | Pts/min | Assists | Turnovers | Ast − TO |
|---|---|--:|--:|--:|--:|
| NYK | Jordan Clarkson | 0.47 | 1 | 4 | -3 |
| NYK | Jose Alvarado | 0.35 | 7 | 2 | **+5** |
| NYK | Landry Shamet | 0.28 | 5 | 0 | **+5** |
| NYK | Miles McBride | 0.17 | 7 | 3 | +4 |
| SAS | Dylan Harper | 0.58 | 15 | 6 | +9 |
| SAS | Carter Bryant | 0.40 | 0 | 2 | -2 |
| SAS | Keldon Johnson | 0.29 | 3 | 3 | 0 |
| SAS | Luke Kornet | 0.07 | 2 | 1 | +1 |

**What the data shows:** Harper aside (he played starter-level minutes and only lands in this
bucket because Wembanyama, Castle, Fox, Vassell and Champagnie logged more), the Knicks' reserves
were at worst break-even — Alvarado, Clarkson and Hukporti all finished with positive plus/minus,
and Alvarado, Shamet and McBride each had a clean assist-to-turnover margin. San Antonio's bench,
outside Keldon Johnson, was net-negative. Note that plus/minus over five games and small minute
totals is noisy; the useful read is the direction, not the exact figures.

## Question 1 — what the numbers point to

The Knicks entered with a clearer scoring hierarchy (Brunson → Anunoby → Towns) and got
non-negative minutes from their bench. The Spurs spread the ball more evenly but had no single
engine at Brunson's volume and got little from reserves beyond Keldon Johnson. Whether
concentration *caused* the result can't be shown from one series — but "more top-heavy team,
steadier bench" is the pattern that separated them here.

---

# Question 2 — Who rose, and who fell short of their regular-season form?

`queries/question2_playoff_pressure_or_pop_off.sql` builds a `labels` table: for every player,
the percentage change from their **regular-season per-game averages** to their **Finals
per-game averages**, then bucketed with CASE logic —

- **Role** (from minutes): within ±10% = *Same Role*, ≥ +10% = *Expanded*, ≤ −10% = *Reduced*
- **Scoring / Rebound / Assist**: ≥ +10% = *Improved*, ≤ −10% = *Declined*, else *Consistent*
- **Shots** (FG attempts): ≥ +10% = *More Aggressive*, ≤ −10% = *Less Aggressive*, else *Consistent*

### Knicks — every player with a Finals appearance, by minutes change

| Player | Min % | Pts % | Reb % | Ast % | FGA % | Role | Scoring | Rebound | Assist | Shots |
|---|--:|--:|--:|--:|--:|---|---|---|---|---|
| Pacome Dadiet | +27 | +73 | +7 | +4 | +38 | Expanded | Improved | Consistent | Consistent | More Aggressive |
| Josh Hart | +8 | -13 | +22 | -5 | +2 | Same | Declined | Improved | Consistent | Consistent |
| Jalen Brunson | +6 | +9 | -5 | -11 | +9 | Same | Consistent | Consistent | Declined | Consistent |
| OG Anunoby | +4 | +21 | +20 | -24 | -3 | Same | Improved | Improved | Declined | Consistent |
| Karl-Anthony Towns | -1 | -21 | -11 | +64 | -28 | Same | Declined | Declined | Improved | Less Aggressive |
| Mikal Bridges | -2 | -6 | -16 | -26 | -16 | Same | Consistent | Declined | Declined | Less Aggressive |
| Ariel Hukporti | -16 | -22 | +9 | -44 | -26 | Reduced | Declined | Consistent | Declined | Less Aggressive |
| Mohamed Diawara | -21 | -67 | +10 | +30 | -30 | Reduced | Declined | Improved | Improved | Less Aggressive |
| Mitchell Robinson | -28 | -15 | -37 | -55 | -16 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Landry Shamet | -28 | -36 | -39 | -48 | -37 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Miles McBride | -33 | -53 | -50 | -53 | -44 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Jordan Clarkson | -38 | -43 | -2 | -54 | -41 | Reduced | Declined | Consistent | Declined | Less Aggressive |
| Tyler Kolek | -42 | -21 | -53 | -45 | -22 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Jose Alvarado | -44 | -37 | -32 | -69 | -38 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Jeremy Sochan | -52 | -9 | -71 | -67 | -40 | Reduced | Consistent | Declined | Declined | Less Aggressive |

### Spurs — every player with a Finals appearance, by minutes change

| Player | Min % | Pts % | Reb % | Ast % | FGA % | Role | Scoring | Rebound | Assist | Shots |
|---|--:|--:|--:|--:|--:|---|---|---|---|---|
| Dylan Harper | +19 | +20 | +64 | -30 | +7 | Expanded | Improved | Improved | Declined | Consistent |
| Victor Wembanyama | +18 | -5 | -6 | -14 | -2 | Expanded | Consistent | Consistent | Declined | Consistent |
| Devin Vassell | +15 | -7 | +32 | +8 | -6 | Expanded | Consistent | Improved | Consistent | Consistent |
| Julian Champagnie | +12 | +1 | -1 | +1 | +1 | Expanded | Consistent | Consistent | Consistent | Consistent |
| Stephon Castle | +11 | +9 | -5 | -17 | +7 | Expanded | Consistent | Consistent | Declined | Consistent |
| De'Aaron Fox | +9 | -16 | 0 | -4 | -1 | Same | Declined | Consistent | Consistent | Consistent |
| Keldon Johnson | -23 | -41 | -38 | -36 | -28 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Carter Bryant | -25 | -37 | -31 | +3 | -46 | Reduced | Declined | Declined | Consistent | Less Aggressive |
| Jordan McLaughlin | -26 | -6 | +10 | +16 | -39 | Reduced | Consistent | Improved | Improved | Less Aggressive |
| Luke Kornet | -38 | -44 | -36 | -62 | -37 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Lindy Waters III | -46 | -30 | -8 | -6 | -34 | Reduced | Declined | Consistent | Consistent | Less Aggressive |
| Bismack Biyombo | -50 | -28 | -68 | -100 | +30 | Reduced | Declined | Declined | Declined | More Aggressive |
| Kelly Olynyk | -54 | -12 | -57 | -71 | -27 | Reduced | Declined | Declined | Declined | Less Aggressive |
| Mason Plumlee | -59 | -20 | -69 | -50 | +50 | Reduced | Declined | Declined | Declined | More Aggressive |
| Harrison Barnes | -64 | -77 | -53 | -87 | -74 | Reduced | Declined | Declined | Declined | Less Aggressive |

### Rose to the occasion

- **Dylan Harper (SAS)** — bigger role *and* better output: +19% minutes, +20% points, +64%
  rebounds, and a team-best +9 assist-to-turnover margin. The only Spur whose Finals averages
  beat his regular-season baseline across multiple categories.
- **OG Anunoby (NYK)** — same minutes, +21% points and +20% rebounds; the Knicks starter whose
  per-game production rose the most.
- **Karl-Anthony Towns (NYK)** — not more scoring (−21% points, −28% FG attempts) but a shifted
  role: +64% assists. A change in how he was used, not a drop-off.
- **Josh Hart (NYK)** — +22% rebounds on flat minutes.

*(Pacome Dadiet's +73% points is in the table but comes on garbage-time minutes — small
denominator, not a signal.)*

### Fell short of their regular-season form

- **San Antonio's veteran frontcourt** — Barnes (−64% minutes, −77% points), Olynyk, Plumlee
  and Biyombo all lost 50%+ of their minutes. This is largely a rotation decision: the Spurs
  shortened their bench and leaned younger for the Finals.
- **De'Aaron Fox (SAS)** — kept the same role (−9% minutes, essentially unchanged FG attempts)
  but scored 16% less per game.
- **Victor Wembanyama (SAS)** — absorbed +18% more minutes without more production (−5% points,
  −6% rebounds).
- **Mikal Bridges (NYK)** — same minutes, down across the board: −6% points, −16% rebounds,
  −26% assists, −16% FG attempts.

### Question 2 — what the numbers point to

The Knicks mostly held or improved inside stable roles — five of their top six were *Same Role*
on minutes, with Anunoby up, Towns re-cast as a passer, and only Bridges slipping. The Spurs'
side is defined by change: Harper is the one clear riser, Wembanyama took on more without more
output, Fox regressed at unchanged usage, and the veteran bench dropped out of the rotation.

---

## Limitations

- **One five-game series.** No significance or effect-size testing; single-series percentage
  changes can be driven by shooting variance.
- **"Bench" definition.** `minutes_rank > 5` places genuine sixth men (Harper, Shamet) in the
  reserve bucket.
- **Reduced role ≠ underperformance.** A player losing minutes (e.g. the Spurs' bigs) reflects a
  coaching decision as much as individual play.
- **Regular-season baseline.** Q2 compares against *all* of a player's regular-season games, not
  a strength-of-opponent-matched subset.
- **`usage_pct`.** The imported values sit on an unusual 0–1 scale; the column is excluded from
  the write-up pending a check against the source CSV.

## Possible extensions

- Refactor the repeated `game_type = 'Playoffs' AND home/away IN (20, 27)` filter into a
  `finals_player_games` view.
- Add a minutes floor to Q2 (e.g. ≥ 8 Finals mpg) so rotation players aren't buried among
  garbage-time lines.
- Per-game trend: did the Knicks' scoring concentration grow as the series went on?
- Visualizations (Tableau).
