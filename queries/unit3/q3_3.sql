--3.3

-- The question: How many participant records 
-- have a network timeout disconnect reason, 
-- and which matches and players were involved?

-- 1. Using a subquery with IN/NOT IN
SELECT mp.participation_id, mp.match_id, mp.player_id
FROM match_participants mp
WHERE mp.participation_id IN (
    SELECT participation_id
    FROM match_participants
    WHERE disconnect_reason = 'Network timeout'
)
ORDER BY mp.participation_id;

-- 2. Using a CTE
WITH timeout_participants AS (
    SELECT participation_id
    FROM match_participants
    WHERE disconnect_reason = 'Network timeout'
)
SELECT mp.participation_id, mp.match_id, mp.player_id
FROM match_participants mp
JOIN timeout_participants tp
    ON mp.participation_id = tp.participation_id
ORDER BY mp.player_id;

-- 3. Using set difference
SELECT participation_id, match_id, player_id
FROM match_participants
WHERE disconnect_reason IS NOT NULL
EXCEPT
	SELECT participation_id, match_id, player_id
	FROM match_participants
	WHERE disconnect_reason <> 'Network timeout'
ORDER BY participation_id;

-- 4. 	The following does a series of comparisons between
-- 		the 3 versions, finding rows that exists in 1 but not the other
-- 		All comparisons return nothing. This proves they contain
-- 		the exact same rows

-- version 1 vs version 2
WITH
version_1 AS (
    SELECT participation_id, match_id, player_id
    FROM match_participants
    WHERE participation_id IN (
        SELECT participation_id
        FROM match_participants
        WHERE disconnect_reason = 'Network timeout'
    )
),
version_2 AS (
    WITH timeout_participants AS (
        SELECT participation_id
        FROM match_participants
        WHERE disconnect_reason = 'Network timeout'
    )
    SELECT mp.participation_id, mp.match_id, mp.player_id
    FROM match_participants mp
    JOIN timeout_participants tp
        ON mp.participation_id = tp.participation_id
)
SELECT * FROM version_2
EXCEPT
SELECT * FROM version_1;

--version 2 vs version 1
WITH
version_1 AS (
    SELECT participation_id, match_id, player_id
    FROM match_participants
    WHERE participation_id IN (
        SELECT participation_id
        FROM match_participants
        WHERE disconnect_reason = 'Network timeout'
    )
),
version_2 AS (
    WITH timeout_participants AS (
        SELECT participation_id
        FROM match_participants
        WHERE disconnect_reason = 'Network timeout'
    )
    SELECT mp.participation_id, mp.match_id, mp.player_id
    FROM match_participants mp
    JOIN timeout_participants tp
        ON mp.participation_id = tp.participation_id
)
SELECT * FROM version_1
EXCEPT
SELECT * FROM version_2;

-- Now it is confirmed version 1 and 2 are the same results
-- Either can be compared with 3 now

--version 1 vs version 3
WITH
version_1 AS (
    SELECT participation_id, match_id, player_id
    FROM match_participants
    WHERE participation_id IN (
        SELECT participation_id
        FROM match_participants
        WHERE disconnect_reason = 'Network timeout'
    )
),
version_3 AS (
	SELECT participation_id, match_id, player_id
	FROM match_participants
	WHERE disconnect_reason IS NOT NULL
	EXCEPT
		SELECT participation_id, match_id, player_id
		FROM match_participants
		WHERE disconnect_reason <> 'Network timeout'
	ORDER BY participation_id
)
SELECT * FROM version_1
EXCEPT
SELECT * FROM version_3;

--version 3 vs version 1
WITH
version_1 AS (
    SELECT participation_id, match_id, player_id
    FROM match_participants
    WHERE participation_id IN (
        SELECT participation_id
        FROM match_participants
        WHERE disconnect_reason = 'Network timeout'
    )
),
version_3 AS (
	SELECT participation_id, match_id, player_id
	FROM match_participants
	WHERE disconnect_reason IS NOT NULL
	EXCEPT
		SELECT participation_id, match_id, player_id
		FROM match_participants
		WHERE disconnect_reason <> 'Network timeout'
	ORDER BY participation_id
)
SELECT * FROM version_1
EXCEPT
SELECT * FROM version_3;

-- 5. Naming an input condition which would change their equivalence:
-- One condition that can break equivalence is the presence of NULL 
-- values in disconnect_reason. A set-difference query that subtracts 
-- rows where the reason is not a network timeout may retain records 
-- with NULL reasons, because comparisons against NULL evaluate to UNKNOWN. 
-- A direct equality filter excludes those records. Therefore, the 
-- set-difference query must explicitly handle NULL values to return the same results.