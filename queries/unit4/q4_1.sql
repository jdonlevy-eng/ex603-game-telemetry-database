-- 4.1.1 Find the following stats in MATCH_PARTICIPANTS
-- Match Pariticpants count
-- Sum of Scores
-- Average score
-- Minimum score
-- Maximum score
-- Unique Player count
-- Filtering out abandoned player matches to remove 0 scores from poluting stats
-- This is a data quality issue, also notice that all 0 scores are abandoned
-- matches with no left_at timestamp

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

-- 4.1.2 Find match_participants and average score for each match
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

-- 4.1.3 To avoid low player count matches from throwing off error rate
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

-- 4.1.4 The picture changes when comparing number
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

