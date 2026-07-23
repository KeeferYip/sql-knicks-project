-- Filtered CSV for current relative NBA teams

INSERT
	INTO
	teams (team_id,
	raw_team_id,
	team_name)
SELECT 
	ROW_NUMBER() OVER(ORDER BY teamcity ASC) AS team_id,
	teamid AS raw_team_id,
	CONCAT(teamcity, ' ', teamname) AS team_name
FROM
	raw_teams
WHERE
	league = 'NBA'
	AND seasonactivetill = 2100
	AND teamid > 10000;

-- Updated column data type to prevent data import error

ALTER TABLE raw_player_stats
ALTER COLUMN "seriesgamenumber" TYPE varchar;

-- Picking out unique player and team info from raw 

INSERT
	INTO
	players (player_id,
	player_name)
SELECT
	DISTINCT
    r."personid",
	CONCAT(r."firstname", ' ', r."lastname")
FROM
	raw_player_stats r
WHERE
	r."gamedatetimeest" > '2025-10-01'
	AND (r."gametype" NOT IN ('Preseason', 'All-Star Game')
		OR r."gametype" IS NULL);
-- populating player_teams with respective ids
INSERT
	INTO
	player_teams (player_id,
	team_id)
SELECT
	DISTINCT
    r."personid",
	t.team_id
FROM
	raw_player_stats r
JOIN teams t
    ON
	CONCAT(r."playerteamcity", ' ', r."playerteamname") = t.team_name
WHERE
	r."gamedatetimeest" > '2025-10-01'
	AND (
    r."gametype" NOT IN ('Preseason', 'All-Star Game')
		OR r."gametype" IS NULL
);
-- Filtering raw_games for NBA games only and re-assigning IDs
INSERT
	INTO
	games(
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
FROM
	rawgames AS rg
	-- Mapping home team to new team_id
JOIN teams AS home 
	ON
	rg."hometeamId" = home.raw_team_id
	-- Mapping away team to new team_id
JOIN teams AS away
	ON
	rg."awayteamId" = away.raw_team_id
	-- Joining winning team IDs
JOIN teams AS winner
	ON
	rg."winner" = winner.raw_team_id
WHERE 
	"gameDateTimeEst" > '2025-10-01'
	AND ("gameType" NOT IN ('Preseason', 'All-Star Game')
		OR "gameType" IS NULL);


-- Alter original player and team stats tables with updated variables of interest 
ALTER TABLE player_stats 
DROP COLUMN efficiency,
ADD COLUMN fgs_made int,
ADD COLUMN fgs_attempted int,
ADD COLUMN three_pts_made int,
ADD COLUMN three_pts_attempted int,
ADD COLUMN fts_made int,
ADD COLUMN fts_attempted int,
ADD COLUMN usage_pct NUMERIC;

ALTER TABLE team_stats 
ADD COLUMN fgs_made int,
ADD COLUMN fgs_attempted int,
ADD COLUMN three_pts_made int,
ADD COLUMN three_pts_attempted int,
ADD COLUMN fts_made int,
ADD COLUMN fts_attempted int;

-- Updated games table to include game type
ALTER TABLE games
ADD COLUMN game_type varchar;

UPDATE 
	games g
SET game_type = r."gameType"
FROM rawgames r
WHERE game_id = r."gameId";

ALTER TABLE games
ALTER COLUMN game_type SET NOT NULL;

-- Populate player_stats table
INSERT INTO player_stats (
	player_id,
	game_id, 
	team_id,
	minutes,
	points,
	rebounds,
	assists,
	steals,
	blocks,
	turnovers,
	plus_minus,
	fgs_made,
	fgs_attempted,
	three_pts_made,
	three_pts_attempted,
	fts_made,
	fts_attempted,
	usage_pct
)

SELECT 
	r.personid,
	r.gameid,
	t.team_id,
	r.numminutes,
	r.points,
	r.reboundstotal,
	r.assists,
	r.steals,
	r.blocks,
	r.turnovers,
	r.plusminuspoints,
	r.fieldgoalsmade,
	r.fieldgoalsattempted,
	r.threepointersmade,
	r.threepointersattempted,
	r.freethrowsmade,
	r.freethrowsattempted,
	r.usagepercentage
FROM raw_player_stats AS r
JOIN games AS g
ON r.gameid = g.game_id
JOIN teams AS t
ON r.playerteamid = t.raw_team_id;

-- Populating team_stats
INSERT INTO team_stats(
	team_id,
	game_id,
	total_points,
	fg_pct,
	rebounds,
	assists,
	steals,
	blocks,
	fgs_made,
	fgs_attempted,
	three_pts_made,
	three_pts_attempted,
	fts_made,
	fts_attempted
)

SELECT 
	t.team_id,
	r.gameid,
	r.teamscore,
	r.fieldgoalspercentage,
	r.reboundstotal,
	r.assists,
	r.steals,
	r.blocks,
	r.fieldgoalsmade,
	r.fieldgoalsattempted,
	r.threepointersmade,
	r.threepointersattempted,
	r.freethrowsmade,
	r.freethrowsattempted
FROM raw_team_stats AS r
JOIN games AS g
ON r.gameid = g.game_id
JOIN teams AS t
ON r.teamid = t.raw_team_id;