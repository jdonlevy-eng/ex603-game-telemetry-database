-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Game Telemetry
-- Author: James Donlevy
-- Target: PostgreSQL 18.6
-- =================================================================
-- Reset. Reverse creation order, so no dependency blocks a drop.
 
DROP TABLE IF EXISTS scores    CASCADE;
DROP TABLE IF EXISTS match_participants    CASCADE;
DROP TABLE IF EXISTS match_modes   CASCADE;
DROP TABLE IF EXISTS matches   CASCADE;
DROP TABLE IF EXISTS game_modes   CASCADE;
DROP TABLE IF EXISTS players    CASCADE;

-- ----------------------------------------------------------------
-- 1. players — first, because it references no other table.
--  The order of the first 3 tables could be interchanged without consequence.
-- ----------------------------------------------------------------

CREATE TABLE players (
	player_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	username VARCHAR(30) NOT NULL UNIQUE,
	email VARCHAR(255) NOT NULL UNIQUE,
	region VARCHAR(5) NOT NULL,
	platform VARCHAR(11) NOT NULL,
	status VARCHAR(8) NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT chk_region_values
	CHECK (region in ('NA','LATAM','EU','MENA','AF','SA','SEA','EA','OCE')),
	CONSTRAINT chk_platform_values
	CHECK (platform in ('Xbox','Playstation','PC','Mobile')),
	CONSTRAINT chk_status_values
	CHECK (status in ('active','banned','inactive'))
);

-- ----------------------------------------------------------------
-- 2. matches — Also references nothing. Could be interchanged with
-- 1 or 3
-- ----------------------------------------------------------------

CREATE TABLE matches(
	match_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	map_name VARCHAR(100) NOT NULL,
	server_region VARCHAR(5) NOT NULL,
	started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	ended_at TIMESTAMP NULL,
	duration INTERVAL
    GENERATED ALWAYS AS (ended_at - started_at) STORED,
	match_status VARCHAR(11) NOT NULL DEFAULT 'MATCHMAKING',
	CONSTRAINT chk_server_region_values
	CHECK (server_region in ('NA','LATAM','EU','MENA','AF','SA','SEA','EA','OCE')),
	CONSTRAINT chk_match_status_values
	CHECK (match_status in ('MATCHMAKING','LOBBY','IN_PROGRESS','CANCELLED','COMPLETE')),
	CONSTRAINT ended_after_started
	CHECK (ended_at IS NULL OR ended_at >= started_at)
);

-- ----------------------------------------------------------------
-- 3. game_modes — Also references nothing. Could be interchanged
-- with 1 or 2. It made sense to me to create all the tables
-- that do not reference anything first, although it may be worth
-- noting I could have delayed creating this one until it was 
-- needed to reference another table.
-- ----------------------------------------------------------------

CREATE TABLE game_modes(
	game_mode_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name VARCHAR(18) NOT NULL,
	description VARCHAR(255) NOT NULL,
	max_players INTEGER NOT NULL DEFAULT 16,
	min_players INTEGER NOT NULL DEFAULT 2,
	CONSTRAINT chk_name_values
	CHECK (name in ('TEAM_DEATHMATCH','CAPTURE_THE_FLAG','SEARCH_AND_DESTROY','DOMINATION')),
	CONSTRAINT chk_max_players_between
	CHECK (max_players > 2 AND max_players < 20),
	CONSTRAINT chk_min_players_between
	CHECK (min_players > 2 AND min_players < 20)	
);

-- ----------------------------------------------------------------
-- 4. match_participants — This junction table handles the 
-- m : n relationship between players and matches. As such both
-- have to be created before this.
-- ----------------------------------------------------------------

CREATE TABLE match_participants(
	match_participant_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	match_id INTEGER NOT NULL,
	player_id INTEGER NULL,
	team_name VARCHAR(11) NOT NULL,
	character VARCHAR(25) NOT NULL,
	joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	left_at TIMESTAMP NULL,
	kills INTEGER NOT NULL DEFAULT 0,
	assists INTEGER NOT NULL DEFAULT 0,
	deaths INTEGER NOT NULL DEFAULT 0,
	result VARCHAR(4) NULL,
	CONSTRAINT fk_match_id
	FOREIGN KEY (match_id) REFERENCES matches (match_id)
	ON DELETE CASCADE,
	CONSTRAINT fk_player_id
	FOREIGN KEY (player_id) REFERENCES players (player_id)
	ON DELETE SET NULL,
	CONSTRAINT chk_team_name_values
	CHECK (team_name in ('TERMINATORS','HUMANS')),
	CONSTRAINT chk_character_values
	CHECK (character in ('T-800', 'T-850', 'T-1000', 'T-X', 'T-3000', 'T-5000', 'T-600', 'T-700',
		'Resistance Soldier', 'Resistance Commander', 'Resistance Scout', 'Resistance Medic', 'Resistance Engineer', 'Resistance Sniper', 'Resistance Heavy Gunner', 'Resistance Technician')),
	CONSTRAINT chk_kills_pos
	CHECK (kills >= 0),
	CONSTRAINT chk_assists_pos
	CHECK (assists >= 0),
	CONSTRAINT chk_deaths_pos
	CHECK (deaths >= 0),
	CONSTRAINT chk_result_values
	CHECK (result IN ('WIN','LOSS'))		
);

-- ----------------------------------------------------------------
-- 5. match_modes — m:n junction between matches and game_modes
-- Requires game_modes and matches to be created
-- first. I could have swapped this with 4 but it really doesnt matter
-- ----------------------------------------------------------------

CREATE TABLE match_modes(
	match_id INTEGER NOT NULL,
	game_mode_id INTEGER NOT NULL,
	CONSTRAINT pk_match_modes
	PRIMARY KEY (match_id,game_mode_id),
	CONSTRAINT fk_match_id
	FOREIGN KEY (match_id) REFERENCES matches(match_id)
	ON DELETE CASCADE,
	CONSTRAINT fk_game_mode_id
	FOREIGN KEY (game_mode_id) REFERENCES game_modes(game_mode_id)
	ON DELETE CASCADE
);

-- ----------------------------------------------------------------
-- 6. scores — 1 match_participant to many scores. 
-- I chose to do this last since it is the lowest in 
-- the hierarchy. Both matches, players, and match_participants
-- all need to be created prior to this. 
-- Additionally this table is required to handle multivalued
-- resolution if scores were kept in the match_participant table,
-- however it requires its own key because score_types can be repeated
-- ----------------------------------------------------------------

CREATE TABLE scores(
	score_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	match_participant_id INTEGER NOT NULL,
	score_type VARCHAR(18) NOT NULL,
	weapon VARCHAR(25) NULL,
	points INTEGER NOT NULL,
	recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_match_participant_id
	FOREIGN KEY (match_participant_id) REFERENCES match_participants(match_participant_id)
	ON DELETE CASCADE,
	CONSTRAINT chk_score_type_values
	CHECK(score_type in ('Kill', 'Assist', 'Headshot', 'Melee Kill', 'Flag Capture', 'Flag Return',
'Domination Capture', 'Domination Defense', 'Objective Capture', 'Objective Defense',
'Revive', 'Heal', 'Repair', 'Resupply', 'Spot Enemy', 'Destroy Vehicle',
'Destroy Objective', 'Plant Bomb', 'Defuse Bomb', 'Escort', 'Payload Progress',
'Kill Streak', 'Multi-Kill', 'Longshot', 'Revenge Kill', 'First Blood',
'Team Elimination', 'Match Victory')),
	CONSTRAINT chk_points_pos
	CHECK (points > 0)	
)

