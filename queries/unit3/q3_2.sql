-- Part A: The rows that vanished

-- This query silently ignores the rows where disconnect_reason = NULL
-- (due to SQL 3 valued logic)
SELECT
  COUNT(*) AS "Number of match_paritipants that did not timeout"
FROM match_participants
WHERE disconnect_reason <> 'Network timeout'

-- This query shows the counts of disconnect reasons
-- Here you can see that the previous query counted only
-- the Client crash, Network timeout, and server restart
-- silently omitting null counts. As you can see in this
-- query the totals combine to 200 rows
SELECT
	disconnect_reason,
	COUNT(*) AS "NUMBER OF PLAYERS"
FROM match_participants
GROUP BY disconnect_reason

-- Using COALESCE we replace null in the comparison
-- with 'No Reason' allowing for the nulls to be 
-- represented in the count
SELECT
  COUNT(*) AS "Number of match_paritipants that did not timeout"
FROM match_participants
WHERE COALESCE(disconnect_reason,'No Reason') <> 'Network timeout'



-- Part B: The Alias that did not exist

--The following query triggers an error for its usage of an
-- alias in the WHERE clause
SELECT
	duration_min as PlayTime
FROM match_participants
WHERE PlayTime > 5

-- First rewrite repeating statement in WHERE
SELECT
	duration_min as PlayTime
FROM match_participants
WHERE duration_min > 5

-- Second rewrite using CTE
WITH match_participants_play_time AS(
	SELECT
		duration_min as PlayTime
	FROM match_participants
)
SELECT
	PlayTime
FROM match_participants_play_time
WHERE PlayTime > 5


	



