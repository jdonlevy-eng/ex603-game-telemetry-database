-- 3.1a Active (Ranked) highly rated (recent high volume) games. 
-- These matches provide a basis to continue investigation
SELECT
	match_id,
	match_label,
	scheduled_on,
	server_region,
	match_code,
	player_count,
	is_ranked
FROM matches
WHERE is_ranked = TRUE AND player_count >= 8
ORDER BY scheduled_on desc
LIMIT 10

--3.1b  All distinct participation_status across all matches with their count
-- This query identifies 3 status (contested,finished,abandoned)
-- I would not have expected abandoned
SELECT 
	participation_status as event_status,
	count(*) as num_of_matches
FROM match_participants
GROUP BY participation_status

-- 3.1c All players who spent less than 5 minutes in a match
-- Looking to see if there is a connection between
-- network timeout and duration however none is observed

SELECT 
	participation_id,
	player_id,
	match_id,
	joined_at,
	left_at,
	client_region,
	score,
	duration_min,
	xp_multiplier,
	participation_status,
	disconnect_reason
FROM match_participants
WHERE duration_min < 5

-- Find all players who contested or abandoned a match
-- Checking for correlation between status and
-- disconnect, none exists

SELECT 
	participation_id,
	player_id,
	match_id,
	joined_at,
	left_at,
	client_region,
	score,
	duration_min,
	xp_multiplier,
	participation_status,
	disconnect_reason
FROM match_participants
WHERE participation_status in ('contested','abandoned')

-- 3.1d Find matches with match_code starting with 'UQ-'
SELECT 
	match_id,
	match_label,
	scheduled_on,
	server_region,
	match_code,
	player_count,
	is_ranked
FROM matches
WHERE match_code LIKE 'UQ-%'

-- Since no values in matches are null, I found disconnect reasons in
-- Match_Participants where value was missing to replace the null values
-- with 'No Reason'

SELECT 
	participation_id,
	player_id,
	match_id,
	joined_at,
	left_at,
	client_region,
	score,
	duration_min,
	xp_multiplier,
	participation_status,
	COALESCE(disconnect_reason,'No Reason')
FROM match_participants

-- 3.1e Created Score Per Minute column to identify
-- player skill based on how quickly they gain score.
-- Assign Good,Medium,Bad as skills based on their
-- score per minute

SELECT
	player_id,
	match_id,
	ROUND(score / duration_min,2) AS "Score Per Minute",
	CASE
		WHEN score/duration_min > 2 THEN 'Good'
		WHEN score/duration_min > 1 THEN 'Medium'
		ELSE 'Bad' 
	END AS "Player Skill"
FROM match_participants










