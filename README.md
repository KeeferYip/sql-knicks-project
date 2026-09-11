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
│   ├── create_tables.sql        # normalized schema (+ one staging table, see below)
│   ├── table_manipulation.sql   # staging -> normalized transforms, column additions
│   └── views.sql                # player_game_total, team_game_total helper views
├── queries/
│   ├── question1_star_vs_depth.sql
│   ├── question1b_hidden_heroes.sql
│   └── question2_playoff_pressure_or_pop_off.sql
└── data/                        # raw CSVs (git-ignored)
```

## How the database is built

1. **Schema** — `create_tables.sql` creates the `raw_teams` staging table and the normalized
   model: `teams`, `players`, `player_teams` (players can change teams mid-season), `games`,
   `player_stats`, `team_stats`.
2. **Load** — the four raw CSVs are imported into staging tables via DBeaver's import wizard,
   which also created `raw_team_stats`, `raw_player_stats`, and `rawgames` directly from the CSV
   headers (100+ columns each, some with inconsistent formatting — e.g. minutes as `"6:08"` in
   some rows). That load step isn't captured as a script: reproducing it with a bare `\copy`
   hits type errors DBeaver's wizard papers over. Since the goal here is the SQL analysis, not a
   fully automated pipeline, the staging load is left as a manual, documented step rather than
   something this repo tries to script end-to-end.
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

## 1a — Star vs Depth

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

# Question 2 — Playoff Pop-Off or Playoff Pressure?

`queries/question2_playoff_pressure_or_pop_off.sql` builds a `labels` table: for every player,
the percentage change from their **regular-season per-game averages** to their **Finals
per-game averages**, then bucketed with CASE logic —

- **Role** (from minutes): within ±10% = *Same Role*, ≥ +10% = *Expanded*, ≤ −10% = *Reduced*
- **Scoring / Rebound / Assist**: ≥ +10% = *Improved*, ≤ −10% = *Declined*, else *Consistent*
- **Shots** (FG attempts): ≥ +10% = *More Aggressive*, ≤ −10% = *Less Aggressive*, else *Consistent*

The full label table covers all 30 players, but most of it is noise — a five-game series makes
every role player's per-game average swing. The table below filters to players who logged real
Finals minutes (`playoff_minutes >= 8`, cutting garbage time) **and** had at least one stat move
by 20% or more — double the ±10% bar used for the labels above — to surface the swings that
actually mean something.

### Notable performances — real minutes, ≥20% swing in at least one stat

| Player | Team | Finals MPG | Min % | Pts % | Reb % | Ast % | FGA % |
|---|---|--:|--:|--:|--:|--:|--:|
| OG Anunoby | NYK | 34.4 | +4 | +21 | +20 | -24 | -3 |
| Josh Hart | NYK | 32.3 | +8 | -13 | +22 | -5 | +2 |
| Karl-Anthony Towns | NYK | 30.4 | -1 | -21 | -11 | +64 | -28 |
| Mikal Bridges | NYK | 32.0 | -2 | -6 | -16 | -26 | -16 |
| Miles McBride | NYK | 17.6 | -33 | -53 | -50 | -53 | -44 |
| Landry Shamet | NYK | 16.3 | -28 | -36 | -39 | -48 | -37 |
| Mitchell Robinson | NYK | 13.9 | -28 | -15 | -37 | -55 | -16 |
| Jordan Clarkson | NYK | 10.8 | -38 | -43 | -2 | -54 | -41 |
| Jose Alvarado | NYK | 9.5 | -44 | -37 | -32 | -69 | -38 |
| Dylan Harper | SAS | 26.8 | +19 | +20 | +64 | -30 | +7 |
| Devin Vassell | SAS | 34.8 | +15 | -7 | +32 | +8 | -6 |
| Keldon Johnson | SAS | 17.8 | -23 | -41 | -38 | -36 | -28 |
| Luke Kornet | SAS | 12.9 | -38 | -44 | -36 | -62 | -37 |
| Carter Bryant | SAS | 8.5 | -25 | -37 | -31 | +3 | -46 |
| Harrison Barnes | SAS | 9.1 | -64 | -77 | -53 | -87 | -74 |

### Rose to the occasion

- **Dylan Harper (SAS)** — bigger role *and* better output: +19% minutes, +20% points, +64%
  rebounds. The only Spur in this table whose Finals averages beat his regular-season baseline
  across multiple categories.
- **OG Anunoby (NYK)** — same minutes, +21% points and +20% rebounds; the Knicks starter whose
  per-game production rose the most.
- **Karl-Anthony Towns (NYK)** — not more scoring (−21% points, −28% FG attempts) but a shifted
  role: +64% assists. A change in how he was used, not a drop-off.
- **Josh Hart (NYK)** — +22% rebounds on flat minutes.

### Fell short of their regular-season form

- **The Knicks bench collapsed almost across the board** — McBride, Shamet, Robinson, Clarkson
  and Alvarado all lost 28–44% of their minutes, and every one of them declined in points,
  rebounds, and assists.
- **Harrison Barnes (SAS)** — the sharpest drop of anyone in the series: −64% minutes, −77%
  points, −53% rebounds, −87% assists.
- **Keldon Johnson, Luke Kornet, Carter Bryant (SAS)** — the rest of San Antonio's bench also
  declined heavily as the Spurs shortened their rotation for the Finals.
- **Mikal Bridges (NYK)** — same minutes, but down across the board: −6% points, −16% rebounds,
  −26% assists, −16% FG attempts.

### The verdict: Playoff Pop Off vs. Playoff Pressure

Ranking the same notable-performance pool by net swing in points + rebounds + assists puts a
number on who rose and who cracked:

**Playoff Pop Off** — Dylan Harper (+54), Karl-Anthony Towns (+33), Devin Vassell (+33)

**Playoff Pressure** — Harrison Barnes (−217), Miles McBride (−157), Luke Kornet (−142)

### Question 2 — what the numbers point to

Among players who saw real minutes and moved by 20% or more in something, the Knicks' story is
their bench: nearly every reserve outside the starting five declined across the board, while the
starters who did show up big (Anunoby, Towns, Hart) held or grew their role rather than getting
more run to compensate. The Spurs' story is Harper rising into an expanded role and everyone
else in this table — from the bench down to Harrison Barnes — losing minutes and production
together as San Antonio shortened its rotation for the Finals.

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
- **The 20%-swing filter can hide "quiet" stories.** A player who kept the same role but produced
  modestly less (e.g. someone a few points off pace at unchanged minutes) won't clear the bar and
  is left out of Q2's table entirely, even if a human analyst would still find it notable.

## Possible extensions

- Refactor the repeated `game_type = 'Playoffs' AND home/away IN (20, 27)` filter into a
  `finals_player_games` view.
- Per-game trend: did the Knicks' scoring concentration grow as the series went on?
- Visualizations (Tableau).
