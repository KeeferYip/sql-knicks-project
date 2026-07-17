-- added a TEMPORARY drop table in case of error 

DROP TABLE IF EXISTS player_stats CASCADE;
DROP TABLE IF EXISTS team_stats CASCADE;
DROP TABLE IF EXISTS players CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS teams CASCADE;


-- Created tables for analyses with respective keys
CREATE TABLE teams(
	team_id int PRIMARY KEY,
	team_name varchar UNIQUE NOT NULL
);

CREATE TABLE players (
	player_id int PRIMARY KEY,
	player_name varchar NOT NULL,
	team_id int NOT NULL,
	
	FOREIGN KEY (team_id) REFERENCES teams(team_id)
	
);

CREATE TABLE games (
	game_id int PRIMARY KEY,
	home_team_id int NOT NULL,
	away_team_id int NOT NULL,
	home_score int NOT NULL,
	away_score int NOT NULL,
	winner_id int NOT NULL,

	FOREIGN KEY (home_team_id) REFERENCES teams(team_id),
	FOREIGN KEY (away_team_id) REFERENCES teams(team_id),
	FOREIGN KEY (winner_id) REFERENCES teams(team_id)

	
	);

-- Note: I included team_id because some players may have been moved mid-season to different teams

CREATE TABLE player_stats (
	player_id int,
	game_id int,
	team_id int NOT NULL,
	minutes NUMERIC NOT NULL,
	points int NOT NULL,
	rebounds int NOT NULL,
	assists int NOT NULL,
	steals int NOT NULL, 
	blocks int NOT NULL, 
	turnovers int NOT NULL,
	plus_minus int NOT NULL,
	efficiency NUMERIC NOT NULL,
	
	PRIMARY KEY (player_id, game_id),
	FOREIGN KEY (player_id) REFERENCES players(player_id),
	FOREIGN KEY (game_id) REFERENCES games(game_id),
	FOREIGN KEY (team_id) REFERENCES teams(team_id)
	
	
	);

CREATE TABLE team_stats (
	team_id int,
	game_id int,
	total_points int NOT NULL,
	fg_pct NUMERIC NOT NULL,
	rebounds int NOT NULL,
	assists int NOT NULL,
	steals int NOT NULL,
	blocks int NOT NULL,
	
	PRIMARY KEY (team_id, game_id),
	FOREIGN KEY (team_id) REFERENCES teams(team_id),
	FOREIGN KEY (game_id) REFERENCES games(game_id)
	
	);





