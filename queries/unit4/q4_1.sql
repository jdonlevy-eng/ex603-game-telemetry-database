-- 4.1.1
-- Question: What are the count, total, average, minimum and maximum score
-- across all sessions, and how many distinct players appear?
-- Note the minimum score is 0. Abandoned participants are recorded with a
-- score of 0, which drags the average down. This is a data quality issue,
-- investigated in the next query

SELECT
	COUNT(*) AS MATCH_PARTICIPANT_COUNT,
	SUM(score) AS TOTAL_SCORE,
	ROUND(AVG(score),2) AS AVERAGE_SCORE,
	MIN(score) AS MINIMUM_SCORE,
	MAX(score) AS MAXIMUM_SCORE,
	COUNT(DISTINCT player_id) AS UNIQUE_PLAYER_COUNT
FROM match_participants;

-- Investigation shows that the match_participants with a score
-- of zero all have participation status of abandoned and
-- have a left_at of null. This may require further analysis

SELECT * FROM match_participants where score = 0;

-- 4.1.2
-- Question: How many sessions and what average score does each match have,
-- from busiest to quietest?
-- As you can see a few matches have lower average scores then most
-- (3,9,11) likely due to their higher number of abandonded players

SELECT
	match_id,
	COUNT(*) AS NUMBER_OF_PLAYERS,
	ROUND(AVG(score),2) AS AVERAGE_MATCH_SCORE,
	COUNT(CASE WHEN participation_status = 'abandoned' THEN 1 END) AS ABANDONDED_PLAYERS
FROM match_participants
GROUP BY match_id
ORDER BY NUMBER_OF_PLAYERS DESC;

-- 4.1.3
-- Question: Which matches have enough sessions (15 or more) for their
-- failure rate to mean anything?
-- To avoid low player count matches from throwing off error rate
-- we will only choose matches with 15 or more players since this is
-- just below the median.

SELECT
	match_id,
	COUNT(*) AS NUMBER_OF_PLAYERS,
	ROUND(AVG(score),2) AS AVERAGE_MATCH_SCORE,
	COUNT(CASE WHEN participation_status = 'abandoned' THEN 1 END) AS ABANDONDED_PLAYERS
FROM match_participants
GROUP BY match_id
HAVING COUNT(*) >= 15
ORDER BY NUMBER_OF_PLAYERS DESC;

-- 4.1.4
-- Question: How do sessions, score and abandonment vary across each
-- combination of server region and the player's connecting region?
-- The picture changes when comparing number
-- of abandoned players across client_region and server_region
-- where APAC, SA has more abandoned players then any other combination

SELECT m.server_region,
       mp.client_region,
       COUNT(*) AS MATCH_PARTICIPANT_COUNT,
       ROUND(AVG(mp.score), 2) AS avg_score,
       COUNT(CASE WHEN mp.participation_status = 'abandoned' THEN 1 END) AS ABANDONED_PLAYERS
FROM match_participants mp
JOIN matches m ON m.match_id = mp.match_id
GROUP BY m.server_region, mp.client_region
ORDER BY ABANDONED_PLAYERS DESC,m.server_region, mp.client_region;

