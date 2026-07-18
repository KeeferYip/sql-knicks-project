-- Filtered CSV for current relative NBA teams

INSERT INTO teams (team_id, team_name)
SELECT 
	ROW_NUMBER() OVER() AS team_id,
	CONCAT(teamcity, ' ', teamname) AS team_name 
FROM raw_teams
WHERE league = 'NBA' AND seasonactivetill = 2100 AND teamid > 10000;


