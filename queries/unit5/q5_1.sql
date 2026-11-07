-- Task 5.1: Connect Producers to Their Data

-- 1. Who are the people behind the events?
-- Assignment 4 identified matches 2,11,9
-- This shows the players and match data 
-- associated with the errors

SELECT 
	match_id,
	player_id,
	p.gamertag,
	mp.joined_at,
	mp.left_at,
	m.scheduled_on
FROM match_participants mp
JOIN matches m USING (match_id)
JOIN players p USING (player_id)
WHERE match_id IN (2,11,9)
ORDER BY match_id,player_id;

-- 2. Do the producers identified share certain
-- catalog credentials/tags

SELECT
	match_id,
	gm.mode_id,
	gm.mode_name,
	mm.enabled_on
FROM matches m
LEFT JOIN match_modes mm USING (match_id)
LEFT JOIN game_modes gm USING (mode_id)
WHERE match_id IN (2,11,9)
ORDER BY match_id;

-- 3. How do the producers compare with one another?
-- Check other matches in the same server region

SELECT
	bad.match_id        AS bad_match,
	good.match_id        AS good_match,
	bad.server_region,
	bad.is_ranked       AS bad_ranked,
	good.is_ranked       AS good_ranked,
	bad.player_count    AS bad_player_count,
	good.player_count    AS good_player_count
FROM matches bad
JOIN matches good ON 
    bad.server_region = good.server_region
    AND good.match_id <> bad.match_id
WHERE bad.match_id IN (2,9,11)
ORDER BY bad.match_id, good.match_id;
