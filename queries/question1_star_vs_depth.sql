/* 
Spurs team id: 27
Knicks team id: 20
*/

-- Create player and team totals as CTEs to later query and perform manipulations
CREATE VIEW pt_share AS 
WITH player_pt_totals AS (
SELECT 
	p.player_name,
	ps.team_id,
	SUM(ps.points) AS player_points
FROM
	player_stats AS ps
JOIN players AS p
ON
	ps.player_id = p.player_id
JOIN games AS g
ON
	ps.game_id = g.game_id
WHERE
	g.game_type = 'Playoffs'
	AND ((g.home_team_id = 20
		OR g.home_team_id = 27)
	AND (g.away_team_id = 20
		OR g.away_team_id = 27))
GROUP BY
	p.player_name,
	ps.team_id
),

team_pt_totals AS (
SELECT 
	ts.team_id, 
	SUM(ts.total_points) AS team_points
FROM team_stats AS ts
JOIN games AS g
ON
	ts.game_id = g.game_id
WHERE
	g.game_type = 'Playoffs'
	AND ((g.home_team_id = 20
		OR g.home_team_id = 27)
	AND (g.away_team_id = 20
		OR g.away_team_id = 27))
GROUP BY ts.team_id
)

-- Created point_share, representing an individual's percentage of the team's overall points
SELECT 
	pt.player_name,
	pt.team_id,
	pt.player_points,
	tt.team_points,
	ROUND(CAST(pt.player_points AS DECIMAL) / tt.team_points, 2) AS point_share,
	RANK() OVER (
   		PARTITION BY pt.team_id
    	ORDER BY pt.player_points DESC
    ) AS scoring_rank
FROM 
	player_pt_totals AS pt
JOIN 
	team_pt_totals AS tt
ON 
	pt.team_id = tt.team_id;

-- breaking down the players on both teams with the top 3 highest point share
SELECT team_id, SUM(point_share) AS t3_pt_share
FROM pt_share
WHERE scoring_rank <= 3
GROUP BY team_id;

-- Examining PRA breakdown per player

WITH player_pra_totals AS (
SELECT 
	p.player_name,
	ps.team_id,
	SUM(ps.points) AS player_points,
	SUM(ps.rebounds) AS player_rebounds,
	SUM(ps.assists) AS player_assists
FROM
	player_stats AS ps
JOIN players AS p
ON
	ps.player_id = p.player_id
JOIN games AS g
ON
	ps.game_id = g.game_id
WHERE
	g.game_type = 'Playoffs'
	AND ((g.home_team_id = 20
		OR g.home_team_id = 27)
	AND (g.away_team_id = 20
		OR g.away_team_id = 27))
GROUP BY
	p.player_name,
	ps.team_id
),

team_pra_totals AS (
SELECT 
	ts.team_id, 
	SUM(ts.total_points) AS team_points,
	SUM(ts.rebounds) AS team_rebounds,
	SUM(ts.assists) AS team_assists
FROM team_stats AS ts
JOIN games AS g
ON
	ts.game_id = g.game_id
WHERE
	g.game_type = 'Playoffs'
	AND ((g.home_team_id = 20
		OR g.home_team_id = 27)
	AND (g.away_team_id = 20
		OR g.away_team_id = 27))
GROUP BY ts.team_id
),

pra_share AS ( 
SELECT 
	pt.player_name,
	pt.team_id,
	pt.player_points,
	pt.player_rebounds,
	pt.player_assists,
	pt.player_points + pt.player_rebounds + pt.player_assists AS player_pra,
	tt.team_points,
	tt.team_rebounds,
	tt.team_assists,
	tt.team_points + tt.team_rebounds + tt.team_assists AS team_pra
FROM 
	player_pra_totals AS pt
JOIN 
	team_pra_totals AS tt
ON 
	pt.team_id = tt.team_id
)

SELECT 
	player_name,
	team_id,
	ROUND(CAST(player_pra AS decimal) / team_pra, 2) AS pra_share
FROM pra_share
ORDER BY pra_share DESC;

-- Exploring usage pct for any identifiable trends
SELECT 
	player_name,
	team_name,
	AVG(usage_pct) AS avg_usage_pct
FROM
	player_game_total
WHERE 
	game_type = 'Playoffs'
AND 
	(team_name IN ('New York Knicks', 'San Antonio Spurs'))
AND
	(opponent_team_name IN ('New York Knicks', 'San Antonio Spurs'))
GROUP BY player_name, team_name
ORDER BY avg_usage_pct DESC;

