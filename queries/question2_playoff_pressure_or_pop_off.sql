/* Create CTEs for regular and playoff player statistic averages for comparison

keeping the CTEs unrounded to prevent distorting differences later
*/

CREATE TEMP TABLE labels AS (
WITH regular_season_avgs AS (
SELECT
	player_id,
	player_name,
	team_id,
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
	player_id,
	player_name,
	team_id
ORDER BY
	avg_minutes DESC
),

playoff_avgs AS (
SELECT
	player_id,
	player_name, 
	team_id,
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
	player_id,
	player_name,
	team_id
ORDER BY
	avg_minutes DESC
),
-- Calculate percent change for basic stats
comparison AS (
SELECT 
	r.player_name,
	r.team_id,
	r.avg_minutes AS reg_minutes,
	p.avg_minutes AS playoff_minutes,
	(p.avg_minutes - r.avg_minutes) / NULLIF(r.avg_minutes, 0) * 100 AS pct_min_change,
	r.avg_points AS reg_points,
	p.avg_points AS playoff_points,
	(p.avg_points - r.avg_points) / NULLIF(r.avg_points, 0) * 100 AS pct_point_change,
	r.avg_rebounds AS reg_rebounds,
	p.avg_rebounds AS playoff_rebounds,
	(p.avg_rebounds - r.avg_rebounds) / NULLIF(r.avg_rebounds, 0) * 100 AS pct_rebound_change,
	r.avg_assists AS reg_assists,
	p.avg_assists AS playoff_assists,
	(p.avg_assists - r.avg_assists) / NULLIF(r.avg_assists, 0) * 100 AS pct_assist_change,
	r.avg_plus_minus AS reg_pm,
	p.avg_plus_minus AS playoff_pm,
	p.avg_plus_minus - r.avg_plus_minus AS pm_change,
	r.avg_fgs_attempted AS reg_fgs_att,
	p.avg_fgs_attempted AS playoff_fgs_att,
	(p.avg_fgs_attempted - r.avg_fgs_attempted) / NULLIF(r.avg_fgs_attempted, 0) * 100 AS pct_fg_att_change,
	r.avg_usage_pct AS reg_usage_pct,
	p.avg_usage_pct AS playoff_usage_pct,
	(p.avg_usage_pct - r.avg_usage_pct) / NULLIF(r.avg_usage_pct, 0) * 100 AS pct_usage_change
FROM
	regular_season_avgs AS r
JOIN 
	playoff_avgs AS p
ON 
	r.player_id = p.player_id
	AND 
	r.team_id = p.team_id
)
-- Create labels for underperforming and excelling players in regards to the playoffs
SELECT
	player_name, 
	team_id,
	reg_minutes,
	playoff_minutes,
	pct_min_change,
	reg_points,
	playoff_points,
	pct_point_change,
	reg_rebounds,
	playoff_rebounds,
	pct_rebound_change,
	reg_assists,
	playoff_assists,
	pct_assist_change,
	reg_fgs_att,
	playoff_fgs_att,
	pct_fg_att_change,
	CASE 
		WHEN pct_min_change >= 10 THEN 'Expanded Role'
		WHEN pct_min_change <= -10 THEN 'Reduced Role'
		ELSE 'Same Role'
	END role_label,
	CASE
		WHEN pct_point_change >= 10 THEN 'Improved'
		WHEN pct_point_change <= -10 THEN 'Declined'
		ELSE 'Consistent'
	END scoring_label,
	CASE
		WHEN pct_rebound_change >= 10 THEN 'Improved'
		WHEN pct_rebound_change <= -10 THEN 'Declined'
		ELSE 'Consistent'
	END rebound_label,
	CASE
		WHEN pct_assist_change >= 10 THEN 'Improved'
		WHEN pct_assist_change <= -10 THEN 'Declined'
		ELSE 'Consistent'
	END assist_label,
	CASE 
		WHEN pct_fg_att_change >= 10 THEN 'More Aggressive'
		WHEN pct_fg_att_change <= -10 THEN 'Less Aggressive'
		ELSE 'Consistent'
	END shots_label
FROM
	comparison
);


-- Identify players who stood out (good and bad) (mainly EDA)
-- *interesting note, all Knicks starters kept a consistent role, while only 1 player (De'Aaron Fox) on the Spurs did
SELECT
	player_name,
	team_id,
	role_label,
	scoring_label,
	rebound_label,
	assist_label,
	shots_label
FROM
	labels
WHERE
	role_label = 'Same Role'
ORDER BY
	team_id;


/* Notable performances: (>= 8 mpg) and at least one stat swinging >= 20% from the regular-season baseline (bigger than the +/-10% bar
used for the Improved/Declined/Same Role labels above)
*/
SELECT
	player_name,
	team_id,
	ROUND(playoff_minutes, 1) AS finals_mpg,
	ROUND(pct_min_change) AS pct_min_change,
	ROUND(pct_point_change) AS pct_point_change,
	ROUND(pct_rebound_change) AS pct_rebound_change,
	ROUND(pct_assist_change) AS pct_assist_change,
	ROUND(pct_fg_att_change) AS pct_fg_att_change,
	role_label,
	scoring_label,
	rebound_label,
	assist_label,
	shots_label
FROM
	labels
WHERE
	playoff_minutes >= 8
	AND (
		ABS(pct_min_change) >= 20
		OR ABS(pct_point_change) >= 20
		OR ABS(pct_rebound_change) >= 20
		OR ABS(pct_assist_change) >= 20
	)
ORDER BY
	team_id,
	GREATEST(ABS(pct_min_change), ABS(pct_point_change), ABS(pct_rebound_change), ABS(pct_assist_change)) DESC;


/* among the players with the biggest changes, rank by net production swing
(points + rebounds + assists % change combined) and assign verdict (Pop Off or Pressure)
*/
SELECT
	player_name,
	team_id,
	ROUND(pct_point_change + pct_rebound_change + pct_assist_change) AS net_production_swing,
	CASE
		WHEN pct_point_change + pct_rebound_change + pct_assist_change > 0 THEN 'Playoff Pop Off'
		ELSE 'Playoff Pressure'
	END AS verdict
FROM
	labels
WHERE
	playoff_minutes >= 8
	AND (
		ABS(pct_min_change) >= 20
		OR ABS(pct_point_change) >= 20
		OR ABS(pct_rebound_change) >= 20
		OR ABS(pct_assist_change) >= 20
	)
ORDER BY
	net_production_swing DESC;
