-- Task 5.1: Connect Producers to Their Data

-- Q1. Incident view for the matches flagged in Assignment 4: who played each match, when, and how their session ended.

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

-- Q2. Do the flagged matches in Assignment 4 share game modes?

SELECT
	gm.mode_name,
	COUNT(*) AS matches_with_mode,
	STRING_AGG(m.match_id::text, ', ' ORDER BY m.match_id) AS all_matches,
	STRING_AGG(CASE WHEN m.match_id IN (2, 9, 11) THEN m.match_id::text END,
	           ', ' ORDER BY m.match_id) AS flagged_matches
FROM matches m
JOIN match_modes mm ON mm.match_id = m.match_id
JOIN game_modes gm  ON gm.mode_id  = mm.mode_id
GROUP BY gm.mode_id, gm.mode_name
ORDER BY gm.mode_id;

-- Q3. How do the flagged matches compare to other matches in the same 
-- server region

SELECT
	flagged.match_id      AS flagged_match,
	peer.match_id         AS peer_match,
	flagged.server_region,
	flagged.is_ranked     AS flagged_ranked,
	peer.is_ranked        AS peer_ranked,
	flagged.player_count  AS flagged_player_count,
	peer.player_count     AS peer_player_count
FROM matches flagged
JOIN matches peer ON
    flagged.server_region = peer.server_region
    AND peer.match_id <> flagged.match_id
WHERE flagged.match_id IN (2,9,11)
ORDER BY flagged.match_id, peer.match_id;


