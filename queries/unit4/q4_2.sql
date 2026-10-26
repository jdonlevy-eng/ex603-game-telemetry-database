-- Task 4.2 Build the breakdown leadership asked for

-- Part A Compute total number of participants, and failure counts by match
-- Excluding player quit disconnect_reason as it does not represent a failure
-- Including unique counts to eliminate scenario where a single player has
-- serveral failures in 1 match
SELECT
	match_id,
	COUNT(*) AS MATCH_PARTICIPANT_COUNT,
	COUNT(DISTINCT player_id) AS UNIQUE_PARTICIPANT_COUNT,
	COUNT(CASE WHEN disconnect_reason = 'Network timeout' THEN 1 END) AS NETWORK_TIMEOUT_CRASH_COUNT,
	COUNT(DISTINCT CASE WHEN disconnect_reason = 'Network timeout' THEN player_id END) AS UNIQUE_NETWORK_TIMEOUT_CRASH_COUNT,
	COUNT(CASE WHEN disconnect_reason = 'Server restart' THEN 1 END) AS SERVER_RESTART_CRASH_COUNT,
	COUNT(DISTINCT CASE WHEN disconnect_reason = 'Server restart' THEN player_id END) AS UNIQUE_SERVER_RESTART_CRASH_COUNT,
	COUNT(CASE WHEN disconnect_reason = 'Client crash' THEN 1 END) AS CLIENT_CRASH_COUNT,
	COUNT(DISTINCT CASE WHEN disconnect_reason = 'Client crash' THEN player_id END) AS UNQIUE_CLIENT_CRASH_COUNT
FROM match_participants
GROUP BY match_id
ORDER BY 
	UNIQUE_NETWORK_TIMEOUT_CRASH_COUNT DESC,
	UNIQUE_SERVER_RESTART_CRASH_COUNT DESC,
	UNQIUE_CLIENT_CRASH_COUNT DESC,
	UNIQUE_PARTICIPANT_COUNT DESC;

-- Part B Subtotals and a grand total of 
-- abandoned participants by server and client regions
SELECT
	CASE WHEN GROUPING(server_region) = 1 THEN 'All server regions'
		ELSE m.server_region END,
	CASE WHEN GROUPING(client_region) = 1 THEN 'All client regions'
		ELSE mp.client_region END,
	COUNT(*) AS MATCH_PARTICIPANT_COUNT,
	COUNT(CASE WHEN disconnect_reason = 'Network timeout' THEN 1 END) AS NETWORK_TIMEOUT_CRASH_COUNT,
	COUNT(CASE WHEN disconnect_reason = 'Server restart' THEN 1 END) AS SERVER_RESTART_CRASH_COUNT,
	COUNT(CASE WHEN disconnect_reason = 'Client crash' THEN 1 END) AS CLIENT_CRASH_COUNT
FROM match_participants mp
JOIN matches m
	ON m.match_id = mp.match_id
GROUP BY ROLLUP(m.server_region,mp.client_region)
ORDER BY 
	NETWORK_TIMEOUT_CRASH_COUNT DESC,
	SERVER_RESTART_CRASH_COUNT DESC,
	CLIENT_CRASH_COUNT DESC;

-- Part C Baseline for High Volume (greater than 15) producers

WITH match_data AS(
	SELECT
		mp.match_id,
		COUNT(*) AS MATCH_PARTICIPANT_COUNT,
		COUNT(CASE 
			WHEN participation_status = 'abandoned' AND disconnect_reason <> 'Player quit'
			THEN 1 END) AS FAILURE_EVENT,
		ROUND(100.0 * COUNT(CASE 
							WHEN participation_status = 'abandoned' AND disconnect_reason <> 'Player quit'
							THEN 1 END)/
							COUNT(*),2) AS FAILURE_RATE_PCT,
		ROUND(AVG(score), 2) AS AVG_SCORE
	FROM match_participants mp
	JOIN matches m
	ON m.match_id = mp.match_id
	GROUP BY MP.match_id
)
SELECT
	COUNT(*) AS HIGH_VOLUME_PRODUCERS,
	SUM(MATCH_PARTICIPANT_COUNT) AS MATCH_PARTICIPANT_COUNT,
	ROUND( 100.0 * SUM(FAILURE_EVENT)/SUM(MATCH_PARTICIPANT_COUNT)) AS TOTAL_FAILURE_RATE,
	ROUND(AVG(FAILURE_RATE_PCT),1) AS AVG_FAILURE_RATE,
	ROUND(AVG(AVG_SCORE),1) AS AVG_SCORE_PER_MATCH
FROM match_data
WHERE MATCH_PARTICIPANT_COUNT >= 15;
