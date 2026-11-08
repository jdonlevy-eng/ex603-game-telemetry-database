-- Task 5.2: Find Records That Joins May Exclude

-- Part A: Compare INNER JOIN and LEFT JOIN

-- 1. Use left join to identify, for each match,
-- the number of players according to match_participants
-- (both distinct and not) and to matches (which is often wrong)

SELECT
	m.match_id,
	COUNT(DISTINCT mp.player_id) AS mp_distinct_player_count,
	COUNT(mp.player_id) AS mp_player_count,
	m.player_count AS matches_stated_player_count
FROM matches m
LEFT JOIN match_participants mp on m.match_id = mp.match_id
GROUP BY m.match_id
ORDER BY m.match_id;

-- 2. Same query but with INNER JOIN

SELECT
	m.match_id,
	COUNT(DISTINCT mp.player_id) AS mp_distinct_player_count,
	COUNT(mp.player_id) AS mp_player_count,
	m.player_count AS matches_stated_player_count
FROM matches m
INNER JOIN match_participants mp on m.match_id = mp.match_id
GROUP BY m.match_id
ORDER BY m.match_id;

-- 3. How many matches does the INNER JOIN exclude?
-- COUNT(DISTINCT mp.match_id) ignores NULLs, so it equals the
-- number of matches the INNER JOIN returns.

SELECT
	COUNT(DISTINCT m.match_id)  AS left_join_matches,
	COUNT(DISTINCT mp.match_id) AS inner_join_matches,
	COUNT(DISTINCT m.match_id) - COUNT(DISTINCT mp.match_id) AS excluded_by_inner_join
FROM matches m
LEFT JOIN match_participants mp on m.match_id = mp.match_id;


-- Part B: Explore RIGHT JOIN and FULL OUTER JOIN

-- 1. RIGHT JOIN achieving the same result as the LEFT JOIN in Part A.1

SELECT
	m.match_id,
	COUNT(DISTINCT mp.player_id) AS mp_distinct_player_count,
	COUNT(mp.player_id) AS mp_player_count,
	m.player_count AS matches_stated_player_count
FROM match_participants mp
RIGHT JOIN matches m on m.match_id = mp.match_id
GROUP BY m.match_id
ORDER BY m.match_id;

-- 2. Verify the LEFT JOIN (Part A.1) and RIGHT JOIN (Part B.1) return the same
-- Both return nothing, set difference left - right & set difference right - left

(SELECT m.match_id, COUNT(DISTINCT mp.player_id), COUNT(mp.player_id), m.player_count
 FROM matches m LEFT JOIN match_participants mp on m.match_id = mp.match_id
 GROUP BY m.match_id)
EXCEPT
(SELECT m.match_id, COUNT(DISTINCT mp.player_id), COUNT(mp.player_id), m.player_count
 FROM match_participants mp RIGHT JOIN matches m on m.match_id = mp.match_id
 GROUP BY m.match_id);

(SELECT m.match_id, COUNT(DISTINCT mp.player_id), COUNT(mp.player_id), m.player_count
 FROM match_participants mp RIGHT JOIN matches m on m.match_id = mp.match_id
 GROUP BY m.match_id)
EXCEPT
(SELECT m.match_id, COUNT(DISTINCT mp.player_id), COUNT(mp.player_id), m.player_count
 FROM matches m LEFT JOIN match_participants mp on m.match_id = mp.match_id
 GROUP BY m.match_id);

-- 3. FULL OUTER JOIN
-- COALESCE keeps the match_id of any match_participants row with no
-- matching match, rather than collapsing them all into one NULL group

SELECT
	COALESCE(m.match_id, mp.match_id) AS match_id,
	COUNT(DISTINCT mp.player_id) AS mp_distinct_player_count,
	COUNT(mp.player_id) AS mp_player_count,
	m.player_count AS matches_stated_player_count
FROM match_participants mp
FULL OUTER JOIN matches m on m.match_id = mp.match_id
GROUP BY COALESCE(m.match_id, mp.match_id), m.player_count
ORDER BY 1;

-- Part C: Find Matches with No Match Participants Using Two Approaches

-- 1. Using NOT EXISTS

SELECT
	m.match_id,
	m.server_region,
	m.is_ranked,
	m.match_code
FROM matches m
WHERE NOT EXISTS(
	SELECT 1 FROM match_participants mp
	WHERE mp.match_id = m.match_id
);

-- 2. Using EXCEPT
SELECT
	m.match_id
FROM matches m
EXCEPT
SELECT
	mp.match_id
FROM match_participants mp
;
