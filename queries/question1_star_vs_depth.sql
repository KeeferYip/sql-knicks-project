/* 
Spurs team id: 27
Knicks team id: 20
*/

-- Create point_share to find out how an individual contributed to the team's overall points 

WITH player_totals AS (
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

team_totals AS (
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
	player_totals AS pt
JOIN 
	team_totals AS tt
ON 
	pt.team_id = tt.team_id;
	
