DROP VIEW IF EXISTS player_game_total;
DROP VIEW IF EXISTS team_game_total;

-- Create a view for player game total stats
CREATE VIEW player_game_total AS
SELECT 
	p.player_name,
	p.player_id,
	ps.team_id,
	t.team_name,
	g.game_id,
	g.game_type,
-- Allows us to filter directly for specific player and opposing teams
	CASE 
		WHEN ps.team_id = g.home_team_id THEN away.team_name
	ELSE home.team_name
END AS opponent_team_name,
	ps.minutes,
	ps.points,
	ps.rebounds,
	ps.assists,
	ps.steals,
	ps.blocks,
	ps.turnovers,
	ps.plus_minus,
	ps.fgs_made,
	ps.fgs_attempted,
	ps.three_pts_made,
	ps.three_pts_attempted,
	ps.fts_made,
	ps.fts_attempted,
	ps.usage_pct
FROM
	player_stats AS ps
JOIN players AS p
	ON
	p.player_id = ps.player_id
JOIN games AS g
	ON
	ps.game_id = g.game_id
JOIN teams AS t 
	ON
	ps.team_id = t.team_id
JOIN teams AS home
	ON
	g.home_team_id = home.team_id
JOIN teams AS away
	ON
	g.away_team_id = away.team_id;

-- Create a view for team game total stats
CREATE VIEW team_game_total AS
SELECT 
	t.team_name,
	ts.team_id,
	g.game_id,
	g.game_type,
	-- Adding opponent team names
	  CASE
		WHEN ts.team_id = g.home_team_id
        THEN away.team_name
		ELSE home.team_name
	END AS opponent,
	ts.total_points,
	ts.fg_pct,
	ts.rebounds,
	ts.assists,
	ts.steals,
	ts.blocks,
	ts.fgs_made,
	ts.fgs_attempted,
	ts.three_pts_made,
	ts.three_pts_attempted,
	ts.fts_made,
	ts.fts_attempted
FROM
	team_stats AS ts
JOIN teams AS t
ON
	t.team_id = ts.team_id
JOIN games AS g
ON
	ts.game_id = g.game_id;