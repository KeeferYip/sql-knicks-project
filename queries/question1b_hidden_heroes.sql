/* Creating a "bench" view to prepare for analyses involving players outside the main rotation 
 * main rotation = Top 5 in minutes 
 */

DROP VIEW IF EXISTS bench;

CREATE VIEW bench AS (
SELECT 
	player_name,
	team_id,
	SUM(minutes) AS total_minutes,
	RANK() OVER (
		PARTITION BY team_id
		ORDER BY SUM(minutes) DESC
	) AS minutes_rank,
	MIN(plus_minus) AS min_plus_minus,
	MAX(plus_minus) AS max_plus_minus,
	AVG(plus_minus) AS avg_plus_minus,
	SUM(points) AS total_points,
	SUM(rebounds) AS total_rebounds,
	SUM(assists) AS total_assists,
	SUM(turnovers) AS total_turnovers
FROM 
	player_game_total
WHERE
	game_type = 'Playoffs'
AND 
	(team_name IN ('New York Knicks', 'San Antonio Spurs'))
AND
	(opponent_team_name IN ('New York Knicks', 'San Antonio Spurs'))
GROUP BY 
	player_name, team_id
);

-- Break down points per minutes for bench players (outside of T5 mins)
SELECT 
	player_name,
	team_id,
	minutes_rank,
	total_points/total_minutes AS pts_per_min
FROM 
	bench 
WHERE 
	minutes_rank > 5
ORDER BY 
	pts_per_min DESC;

-- Show plus minus stats for all bench players
SELECT 
	player_name,
	team_id,
	minutes_rank,
	min_plus_minus,
	max_plus_minus,
	avg_plus_minus
FROM 
	bench 
WHERE 
	minutes_rank > 5;

-- Create an assist plus minus with turnovers to measure how efficient one was with the ball 
SELECT
	player_name,
	team_id,
	minutes_rank,
	total_assists,
	total_turnovers,
	total_assists - total_turnovers AS ast_plus_minus
FROM 
	bench
WHERE minutes_rank > 5;
