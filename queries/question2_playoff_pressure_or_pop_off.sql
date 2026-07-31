-- Create CTEs for regular and playoff player statistic averages for comparison

-- keeping the CTEs unrounded to prevent distorting differences later
WITH regular_season_avgs AS (
SELECT
	player_id,
	player_name, 
	AVG(minutes) AS avg_minutes,
	AVG(points) AS avg_points,
	AVG(rebounds) AS avg_rebounds,
	AVG(assists) AS avg_assists,
	AVG(steals) AS avg_steals,
	AVG(blocks) AS avg_blocks,
	AVG(turnovers) AS avg_turnovers,
	AVG(plus_minus) AS avg_plus_minus,
	AVG(fgs_made) AS avg_fgs_made,
	AVG(fgs_attempted) AS avg_fgs_attempted,
	AVG(three_pts_made) AS avg_three_pts_made,
	AVG(three_pts_attempted) AS avg_three_pts_attempted,
	AVG(fts_made) AS avg_fts_made,
	AVG(fts_attempted) AS avg_fts_attempted,
	AVG(usage_pct) AS avg_usage_pct
FROM 
	player_game_total
WHERE 
	game_type = 'Regular Season'
AND 
	(team_name IN ('New York Knicks', 'San Antonio Spurs'))
GROUP BY 
	player_id, player_name
ORDER BY avg_minutes DESC
),

playoff_avgs AS (
SELECT
	player_id,
	player_name, 
	AVG(minutes) AS avg_minutes,
	AVG(points) AS avg_points,
	AVG(rebounds) AS avg_rebounds,
	AVG(assists) AS avg_assists,
	AVG(steals) AS avg_steals,
	AVG(blocks) AS avg_blocks,
	AVG(turnovers) AS avg_turnovers,
	AVG(plus_minus) AS avg_plus_minus,
	AVG(fgs_made) AS avg_fgs_made,
	AVG(fgs_attempted) AS avg_fgs_attempted,
	AVG(three_pts_made) AS avg_three_pts_made,
	AVG(three_pts_attempted) AS avg_three_pts_attempted,
	AVG(fts_made) AS avg_fts_made,
	AVG(fts_attempted) AS avg_fts_attempted,
	AVG(usage_pct) AS avg_usage_pct
FROM 
	player_game_total
WHERE 
	game_type = 'Playoffs'
AND 
	(team_name IN ('New York Knicks', 'San Antonio Spurs'))
GROUP BY 
	player_id, player_name
ORDER BY avg_minutes DESC
)

-- Calculate change for basic stats
SELECT 
	r.player_name,
	r.avg_minutes AS reg_minutes,
	p.avg_minutes AS playoff_minutes,
	p.avg_minutes - r.avg_minutes AS min_change,
	r.avg_points AS reg_points,
	p.avg_points AS playoff_points,
	p.avg_points - r.avg_points AS point_change,
	r.avg_rebounds AS reg_rebounds,
	p.avg_rebounds AS playoff_rebounds,
	p.avg_rebounds - r.avg_rebounds AS rebound_change,
	r.avg_assists AS reg_assists,
	p.avg_assists AS playoff_assists,
	p.avg_assists - r.avg_assists AS assist_change,
	r.avg_plus_minus AS reg_pm,
	p.avg_plus_minus AS playoff_pm,
	p.avg_plus_minus - r.avg_plus_minus AS pm_change,
	r.avg_fgs_attempted AS reg_fgs_att,
	p.avg_fgs_attempted AS playoff_fgs_att,
	p.avg_fgs_attempted - r.avg_fgs_attempted AS fg_att_change,
	r.avg_usage_pct AS reg_usage_pct,
	p.avg_usage_pct AS playoff_usage_pct,
	(p.avg_usage_pct - r.avg_usage_pct) * 100 AS usage_change
FROM
	regular_season_avgs AS r
JOIN 
	playoff_avgs AS p
ON 
	r.player_id = p.player_id;