-- Task 6.1: Compute across a window without collapsing

-- Q1a. Is a player's score unusual for the match they played in?
--      Returns every participation with its match's average score on the same row.

SELECT
    mp.participation_id,
    mp.match_id,
    p.player_name,
    mp.joined_at,
    mp.participation_status,
    mp.score,
    ROUND(
		AVG(mp.score) OVER(PARTITION BY mp.match_id)
		, 2
	)    AS match_avg_score,
    ROUND(
		mp.score - AVG(mp.score) OVER(PARTITION BY mp.match_id)
		, 2
	)  AS diff_from_match_avg,
    COUNT(*) OVER(PARTITION BY mp.match_id)
		AS participants_in_match
FROM match_participants mp
JOIN players p ON p.player_id = mp.player_id
ORDER BY mp.match_id, diff_from_match_avg DESC;


-- Q1b. What is each match's average score, and what detail does grouping lose?

SELECT
    match_id,
    COUNT(*)              AS participants,
    ROUND(AVG(score), 2)  AS match_avg_score
FROM match_participants
GROUP BY match_id
ORDER BY match_id;


-- Q2.	Which matches draw the most participation?

WITH match_counts AS (
    SELECT
        m.match_id,
		m.server_region,
        COUNT(mp.participation_id) AS participations
    FROM matches m
    LEFT JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id, m.server_region
)
SELECT
    match_id,
	server_region,
    participations,
    ROW_NUMBER() OVER (ORDER BY participations DESC, match_id) AS row_num,
    RANK()       OVER (ORDER BY participations DESC)           AS rnk,
    DENSE_RANK() OVER (ORDER BY participations DESC)           AS dense_rnk
FROM match_counts
ORDER BY participations DESC, match_id;


-- Q3.	Which participation quartile does each match fall in,
--		and do tied matches stay together?

WITH match_counts AS (
    SELECT
        m.match_id,
        m.scheduled_on,
        COUNT(mp.participation_id) AS participations
    FROM matches m
    LEFT JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id, m.scheduled_on
)
SELECT
    match_id,
    scheduled_on,
    participations,
    RANK()   OVER (ORDER BY participations DESC)                    AS rnk,
    NTILE(4) OVER (ORDER BY participations DESC, scheduled_on DESC) AS bucket
FROM match_counts
ORDER BY participations DESC, scheduled_on DESC;
