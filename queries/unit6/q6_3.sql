-- Task 6.3 Build the reporting patterns

-- Part A: Top N per category

-- Which three sessions scored highest on each match (server)?
-- Ties for 3rd are all included in the output since there is no
-- other measureable performance metric to break the tie. Choosing
-- any other method to pick one would not be fair to the player left out.

WITH ranking AS (
	SELECT
		mp.match_id,
		mp.participation_id,
		p.player_name,
		mp.score,
		RANK() OVER(PARTITION BY mp.match_id ORDER BY mp.score DESC) as rnk,
		FIRST_VALUE(mp.score) OVER(PARTITION BY mp.match_id ORDER BY mp.score DESC) as match_highest,
		LAST_VALUE(mp.score) OVER(PARTITION BY mp.match_id ORDER BY mp.score DESC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as match_lowest
	FROM match_participants mp
	JOIN players p ON mp.player_id = p.player_id
)
SELECT
	match_id,
	player_name,
	score,
	rnk,
	match_highest,
	match_lowest
FROM ranking
WHERE rnk <= 3
ORDER BY match_id, rnk;

-- Part B: Period over period

-- Is the platform getting better or worse each month?

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', joined_at)::date AS month,
        COUNT(*) AS sessions,
        COUNT(*) FILTER (WHERE participation_status = 'abandoned'
                           AND disconnect_reason <> 'Player quit') AS failed_sessions,
        100.0 * COUNT(*) FILTER (WHERE participation_status = 'abandoned'
                                 AND disconnect_reason <> 'Player quit') / COUNT(*) AS failure_rate_pct
    FROM match_participants
    GROUP BY DATE_TRUNC('month', joined_at)
),
compared AS (
    SELECT
        *,
        LAG(month)            OVER (ORDER BY month) AS prev_month,
        LAG(failure_rate_pct) OVER (ORDER BY month) AS prev_failure_rate_pct
    FROM monthly
)
SELECT
    month,
    sessions,
    failed_sessions,
    ROUND(failure_rate_pct, 1)      AS failure_rate_pct,
    ROUND(prev_failure_rate_pct, 1) AS prev_failure_rate_pct,
    ROUND(100.0 * (failure_rate_pct - prev_failure_rate_pct)
          / NULLIF(prev_failure_rate_pct, 0), 1) AS pct_change,
    CASE
        WHEN prev_month IS NULL                        THEN 'first month'
        WHEN prev_month <> month - INTERVAL '1 month'  THEN 'MISSING MONTH BEFORE'
        ELSE 'ok'
    END AS month_check
FROM compared
ORDER BY month;
