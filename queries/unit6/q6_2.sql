-- Task 6.2: Compare each row to its neighbors

-- Part A. Is session quality on a game server getting better or worse over time?

WITH score_neighbors AS (
    SELECT
        mp.match_id,
        mp.participation_id,
        p.player_name,
        mp.joined_at,
        mp.participation_status,
        LAG(mp.score) OVER(PARTITION BY mp.match_id ORDER BY mp.joined_at, mp.participation_id) AS prev_score,
        mp.score,
        LEAD(mp.score) OVER(PARTITION BY mp.match_id ORDER BY mp.joined_at, mp.participation_id) AS next_score,
        mp.score - LAG(mp.score) OVER(PARTITION BY mp.match_id ORDER BY mp.joined_at, mp.participation_id) AS delta_from_prev
    FROM match_participants mp
    JOIN players p ON p.player_id = mp.player_id
)
SELECT *
FROM score_neighbors
WHERE match_id = 2
ORDER BY joined_at, participation_id;



-- Part B. How is the platform doing over time, in total and on a recent average?
-- Excluding player quit as a failure

WITH params AS (
    SELECT 50 AS qtr_target
),
daily AS (
    SELECT
        mp.joined_at::date                          AS play_date,
        DATE_TRUNC('quarter', mp.joined_at::date)::date   AS quarter_start,
        COUNT(*)                                    AS sessions,
        COUNT(*) FILTER (WHERE mp.participation_status = 'abandoned'
                           AND mp.disconnect_reason <> 'Player quit') AS failed_sessions
    FROM match_participants mp
    GROUP BY mp.joined_at::date
)
SELECT
    d.play_date, d.quarter_start, d.sessions, d.failed_sessions,
    ROUND(d.failed_sessions::numeric / d.sessions, 2)        AS daily_failure_rate,
    SUM(d.sessions) OVER(PARTITION BY d.quarter_start ORDER BY d.play_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
		AS qtr_running_sessions,
	SUM(d.failed_sessions) OVER(PARTITION BY d.quarter_start ORDER BY d.play_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
		AS qtr_running_failed_sessions,
    p.qtr_target,
    ROUND(100.0 * SUM(d.sessions) OVER(PARTITION BY d.quarter_start ORDER BY d.play_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)/ p.qtr_target, 1)                                     
		AS pct_of_target,
    MIN(d.play_date) OVER (ORDER BY d.play_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)  AS window_start,
    ROUND(AVG(d.failed_sessions::numeric / d.sessions) OVER(ORDER BY d.play_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 3) 
		AS failure_rate_7row_avg
FROM daily d
CROSS JOIN params p
ORDER BY d.play_date;

-- Part C. Where does a server go quiet and then start again?

WITH sessions AS (
    SELECT
        match_id,
		LAG(participation_status) OVER (PARTITION BY match_id ORDER BY joined_at) AS prev_participation_status,
        participation_status,
        LAG(joined_at) OVER (PARTITION BY match_id ORDER BY joined_at) AS prev_joined_at,
        joined_at,
        joined_at - LAG(joined_at) OVER (PARTITION BY match_id ORDER BY joined_at) AS gap
    FROM match_participants
)
SELECT *
FROM sessions
WHERE gap > INTERVAL '80 days'
ORDER BY gap DESC;
