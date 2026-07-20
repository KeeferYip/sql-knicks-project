-- Filtered CSV for current relative NBA teams

INSERT INTO teams (team_id, raw_team_id, team_name)
SELECT 
	ROW_NUMBER() OVER(ORDER BY teamcity ASC) AS team_id,
	teamid AS raw_team_id,
	CONCAT(teamcity, ' ', teamname) AS team_name 
FROM raw_teams
WHERE league = 'NBA' AND seasonactivetill = 2100 AND teamid > 10000;


-- Updated column data type to prevent data import error
ALTER TABLE raw_player_info
ALTER COLUMN "seriesGameNumber" TYPE varchar;

-- Picking out unique player and team info from raw 

INSERT INTO players (player_id, player_name)
SELECT DISTINCT
    r."personId",
    CONCAT(r."firstName", ' ', r."lastName")
FROM raw_player_info r
WHERE r."gameDateTimeEst" > '2025-10-01'
  AND (r."gameType" NOT IN ('Preseason', 'All-Star Game') OR r."gameType" IS NULL);


-- populating player_teams with respective ids
INSERT INTO player_teams (player_id, team_id)
SELECT DISTINCT
	r."personId",
	t.team_id
FROM raw_player_info AS r 
JOIN teams AS t
	ON CONCAT(r."playerteamCity", ' ', r."playerteamName") = t.team_name 
WHERE r."gameDateTimeEst" > '2025-10-01'
  AND (r."gameType" NOT IN ('Preseason', 'All-Star Game') OR r."gameType" IS NULL);
	
	
-- Filtering raw_games for NBA games only and re-assigning IDs
INSERT INTO games(
game_id,
home_team_id,
away_team_id,
home_score,
away_score,
winner_id
)
SELECT 
	DISTINCT 
	rg."gameId",
	home.team_id AS home_team_id,
	away.team_id AS away_team_id,
	rg."homeScore" AS home_score,
	rg."awayScore" AS away_score,
	winner.team_id AS winner_id
FROM rawgames AS rg

-- Mapping home team to new team_id
JOIN teams AS home 
	ON rg."hometeamId" = home.raw_team_id

-- Mapping away team to new team_id
JOIN teams AS away
	ON rg."awayteamId" = away.raw_team_id

-- Joining winning team IDs
JOIN teams AS winner
	ON rg."winner" = winner.raw_team_id

WHERE 
	"gameDateTimeEst" > '2025-10-01'
	AND ("gameType" NOT IN ('Preseason', 'All-Star Game') OR "gameType" IS NULL);
	
	