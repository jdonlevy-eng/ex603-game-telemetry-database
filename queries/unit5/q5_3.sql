-- Task 5.3 Understand Join Performance and Execution Plans

-- Part A: Explore CROSS JOIN

-- 1. Every match platform paired with every game mode (Cartesian product)

SELECT
 plat.*,
 gm.*
FROM match_platforms plat
CROSS JOIN game_modes gm;

-- 2. Does the CROSS JOIN row count equal the product of the two source table counts?
-- Expect 28, 5, 140, 140
SELECT
	(SELECT COUNT(*) FROM match_platforms) AS match_platforms_count,
	(SELECT COUNT(*) FROM game_modes) AS  game_modes_count,
	(SELECT COUNT(*) FROM match_platforms CROSS JOIN game_modes) AS cross_count,
	(SELECT COUNT(*) FROM match_platforms) * 
	(SELECT COUNT(*) FROM game_modes) AS plat_count_mult_gm_count
;

-- Part B: Examine a Query Execution Plan

-- How does PostgreSQL plan to execute the three-table join from Task 5.1 (q5_1.sql query 1)?

EXPLAIN
	SELECT 
		m.match_id,
		m.server_region,
		p.player_name,
		mp.client_region,
		(mp.client_region <> m.server_region) AS cross_region,
		mp.joined_at,
		mp.left_at,
		mp.participation_status,
		mp.disconnect_reason
	FROM match_participants mp
	JOIN matches m ON mp.match_id = m.match_id
	JOIN players p ON mp.player_id = p.player_id
	WHERE m.match_id IN (2,11,9)
	ORDER BY m.match_id, mp.joined_at;