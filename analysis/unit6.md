# Task 6.1: Compute Across a Window Without Collapsing

### 1. Compare each participation score to its match's average

Query 1a in [q6_1.sql](../queries/unit6/q6_1.sql) uses a window function to show participants' scores compared against the match's average, whereas query 1b uses a `GROUP BY` to calculate the match average.

| Version | Rows returned | One row per |
|---|---|---|
| Window function (1a) | 200 | participation |
| GROUP BY (1b) | 13 | match with participations (matches 14 and 15 have none) |

The GROUP BY version merges each match's rows into one, so everything about the individual participations is lost: the participation id, player name, join time, participation status and score. Without the individual score, there is nothing to compare against the average.

### 2. Rank producers three ways

Query 2 ranks all matches by number of participations with `ROW_NUMBER()`, `RANK()` and `DENSE_RANK()` side by side.

A tie between matches 5 and 7 shows how the three functions differ:

* `ROW_NUMBER` (match 5 - rank 4, match 7 - rank 5) Every row gets a unique number, so one tied match has to come first. I added match_id as a tiebreaker so the order is the same every time the query runs, although it has no relevance.
* `RANK` gives both 4, then skips to 6 for match 12. The gap shows that five matches have more participations than match 12.
* `DENSE_RANK` gives both 4, then 5 for match 12. There is no gap, so match 12 has the 5th-highest participation count, but an unknown number of preceding matches.

### 3. Sort producers into four buckets

Query 3 uses `NTILE(4)` to split the matches into 4 buckets by number of participations. Since inclusion of rows in a particular bucket is decided by row position and not value, ties can end up in different buckets non-deterministically. With 15 matches, NTILE makes buckets of 4, 4, 4 and 3. There is a tie between matches 5 and 7 for 18 participants which happens to fall on the boundary between buckets 1 and 2. The `RANK` column shows both at rank 4, yet match 7 is in bucket 1 and match 5 is in bucket 2. If the top bucket decided something important, such as featured placement or extra server capacity, match 5 would miss out only because of how the tie was broken.

To decide the tie (to make it deterministic), I added `scheduled_on DESC` to the `ORDER BY`, so the more recently scheduled match goes in the higher bucket. Although there is not much relevance to this, at least it is repeatable.

### Write Up

1. **Write a question that needs each row shown next to its group's average. Explain why the group average alone (GROUP BY) cannot answer it.**
    * *Which players scored well below the average for the match they played in?* A score of 10 is poor in a match averaging 35 but normal in one averaging 12. For this reason the score has to be compared to the match's average. GROUP BY returns one row per match with only the average, and the individual scores are gone. It can be joined to match_participants for the same result, but a window function can do it in 1 step.

2. **Name a platform feature that would use your ranking, and explain which of the three functions it should use and why.**
    * A **"Top 5 Most Popular Matches"** leaderboard in the game lobby should use `RANK`. Ideally the top 5 would only ever have 5 matches but in the scenario where there is a 6-way tie for 1st, we would want to show all of them since the arbitrarily chosen 6th rank has just as much right to be on the leaderboard as the others. That eliminates `ROW_NUMBER` from consideration. In this scenario there is no way to limit 5 without being unfair however consider a situation where there is a 2-way tie for 4th. If we use `RANK` for rank <=5 we will still get 5 matches (ranks 1,2,3,4,4) whereas `DENSE_RANK` will return 6 (1,2,3,4,4,5) since it doesn't skip 5. In this instance it isn't unfair to remove the 6th entry since it in fact has a lower participation than the match in front of it. This makes `RANK` the clear winner.

# Task 6.2: Compare Each Row to Its Neighbors

### A note on what a "match" is in this dataset

I had originally assumed that the matches in this dataset represented short multiplayer game sessions where multiple players play toward a team goal. This is mostly supported by the available game modes in the game_modes table of Capture the flag, Deathmatch, Survival, Ranked Duel, Time Trial. However I found that the matches.scheduled_on dates vary across the year 2022 while match_participants.joined_at timestamps are all in the year 2023. More importantly, a single match's joined_at timestamps are spread across the whole of 2023 (match 2, for example, runs from January 20th to December 17th). This contradicts my earlier assumption since, well games like that don't last months. It is with this that I will move forward in my analysis under the assumption that a match is a collection of participants' independent game sessions on a common server, across a long period of time.

### Part A: Row to row

Query A in [q6_2.sql](../queries/unit6/q6_2.sql) uses `LAG` and `LEAD`, partitioned by match and ordered by `joined_at`, to put the previous and next session's score on each row. `delta_from_prev` is the current score minus the previous one. The window is calculated for every match, and the outer query keeps only match 2 since it was flagged in previous units.

Match 2 highlights 2 reasons for large deltas:

* **Failures** Abandoned sessions always score 0, so a failed session shows as a sharp drop (for example -15.21 on January 27th). 3 of match 2's first 4 sessions (January to March) were abandoned, then there were none until December. 
* **Performance** On May 4th a player scored 47.81, a +27.98 jump, followed by -32.59 on the next session. Both sessions finished normally which indicates a change in player performance and not failure.

`participation_status` is included to tell them apart, otherwise they would look similar.

### Part B: Cumulative and smoothed

Query B has one row per day with at least one session and adds:

* `qtr_running_sessions` and `qtr_running_failed_sessions`: running totals of sessions and failed sessions within the quarter
* `pct_of_target`: % of the target **50 sessions per quarter**. 50 (200/4) because it keeps pace with the 200 over the year.
* `failure_rate_7row_avg`: the average daily failure rate over the trailing 7 row moving window.
* `window_start`: the first date inside each 7-row window. Since there isn't a session daily this shows the real span of time.

A failure uses the Unit 4 definition: a session dropped by a network timeout, server restart or client crash. Player quits are not considered failure.

**How close the running total gets to the target:**

| Quarter | Sessions | % of target | Failed sessions | Failure rate |
|---|---|---|---|---|
| Q1 | 53 | 106% | 10 | 18.9% |
| Q2 | 48 | 96% | 6 | 12.5% |
| Q3 | 51 | 102% | 6 | 11.8% |
| Q4 | 48 | 96% | 5 | 10.4% |

The target was close or met for each quarter. Failures fell quickly from Q1 to Q2 and then kept falling slowly, so the failure rate went down in every quarter.

The moving average shows the same but in more detail. It shows a max of 0.57 in March when several failures occurred which makes sense since quarter 1 has the highest count. It then drops and stays low until a rise again in June and August, then ends the year low again.

**ROWS vs RANGE:** `ROWS` counts physical rows, so two rows with the same `ORDER BY` value can be in different frames. `RANGE` includes all rows with equal `ORDER BY` values in the frame together. Here each date appears once, so both give the same result.

### Part C: Where the series stops

Query C uses `LAG(joined_at)` to find the previous session on the same match, and calculates the gap between the two in a CTE. The outer query keeps only gaps longer than 80 days. Gaps are common across this dataset. 80 was chosen because 15-20 day gaps are commonly seen, at 4 times that 80 produces only 7 rows with exceptionally long gaps. The filter has to be in the outer query because a window function result cannot be filtered with `WHERE` in the query that calculates it.

Matches 9 (112 days), 12 (106), 5 (93), 11 (89), 1 (86), 2 (86) and 13 (81) were all returned as having exceptionally long gaps.

### Write Up

1. **What would a large delta tell someone about your platform, and what should they do about it?**
    * A large negative delta can mean a session failed, only if the participation_status is abandoned. Abandoned sessions have a score of 0, so the drop is the size of the previous score. Similarly a large positive delta where the previous row showed abandoned would show a recovery from a failure. A group of large negative deltas on one match, like match 2 in January to March, points to a reliability problem on that server, and the server team should check its logs for issues. A large delta (positive or negative) between two finished sessions is a performance indicator. Mostly these can probably be ignored, some players are likely to be better than others. Even the same player is expected to get better over time. If the delta is largely positive it could be an indicator of cheating, but other sources such as game logs may need to be investigated to see how the score was achieved before banning a player.

2. **Why does a running total answer a question that a plain SUM cannot?**
    * A plain `SUM` gives one number: 48 sessions in Q4. It says where the quarter ended, but not how it got there. The running total shows progress on every day of the quarter that there was at least 1 session. In that way action can be taken to try to boost engagement before the quarter ends and we can no longer steer the ship so to speak. The growth for the current data was fairly consistent, in the future that may not always be true.

3. **Why did you pick your moving-average window size? A different size tells a different story.**
    * I chose 7 rows. Only 155 of the 365 days had sessions, so 7 rows cover about 15 calendar days on average. That is roughly two weeks, short enough to show the March failure spike and the quiet spell in April and May as separate events. Each daily failure rate is 0, 0.5 or 1, so the average is noisy. Any larger of a window and it would smooth out events like the March failure to seem insignificant. Any shorter and the noise picks up again making it difficult to discern real events from occasional failure. For this particular set 7 rows is a best fit.

4. **What does a gap mean in your platform: a data quality problem, a real stop in activity, or a side effect of how events were recorded? Say which one yours is and how you know.**
    * Gaps for matches 9, 12, 2, 1 and 13 appear to be ordinary quiet periods. Since the sessions directly before and at the end of those gaps were not abandoned (finished, or contested in match 1's case) it seems there was no evidence of outage. Although that conclusion cannot be proved here, it does point toward that. More interestingly match 11 has the opposite. Both status before and at the end of the gap show abandoned which indicate that perhaps the server was taken offline for failures that were not fully fixed before coming back online. This is unlikely to be lost data, since other matches kept recording during the gap (11 sessions in April and 17 in May). A logging outage would have left gaps on every match. Match 5 had a previous status of abandoned before the gap and then came back with a finished (success) to end the gap. It can be theorized that maybe this server was also taken offline, successfully fixed and brought back. Again it's tough to say conclusively, however it is a good starting point of an investigation into those servers.

# Task 6.3: Build the Reporting Patterns

### Part A: Top 3 per match

Query A in [q6_3.sql](../queries/unit6/q6_3.sql) shows the top 3 scores within each match, using `RANK()` partitioned by match and an outer query that keeps `rnk <= 3`. There are no ties at 3rd place in this data, but if there were, all sessions tied for 3rd would be included in the result. It is preferable to show only 3 results, but since there is no other performance metric to settle the tie, it makes sense to include every tied player. We could break the tie with a non-performance column that is guaranteed unique, like participation_id, but that would be arbitrary and unfair to the player who is ruled out. If there were a tie for 2nd, both tied players would be included and the next would not be.

The query also adds each match's highest and lowest score using `FIRST_VALUE` and `LAST_VALUE`. The default frame stops at the current row. That is fine for `FIRST_VALUE`, which only needs the first row of the window, but `LAST_VALUE` needs the last row, so its frame is overridden with `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`. The lowest score is 0 for most matches, because abandoned sessions always score 0.

### Part B: Period over period

*Is the platform getting better or worse each month?*

There are several ways to judge the quality of the platform, here I continue with session volume and failure rate. Query B groups all sessions by month and shows the total sessions, failed sessions (using the Unit 4 definition, so player quits are excluded), failure rate %, the previous month's failure rate, the % change, and a `month_check` column that confirms each month directly follows the one before. All 12 months of 2023 have sessions, so no months are missing and every comparison is between neighbouring months. May's % change is NULL: April had no failures, and `NULLIF` stops the division by zero.

In general the failure rate goes down over the year, and September to November were the three lowest months after April, at 5.6% to 7.1%. There are a couple of months where it rose again after falling, for example June at 20.0% (a 70% increase over May) and December at 18.8% (a 162.5% increase over November, from just 1 failure to 3).

The platform is not growing. It started strong with 21 sessions in each of January and February, then fell to 11 in March and April. That is not necessarily a bad sign, since launch hype may have inflated the first months and a drop afterwards is common. However, sessions never return to the launch level, staying mostly in the mid to upper teens for the rest of the year.

### Write Up

1. **Name the feature in your platform that top-N would power. Explain why three is the right number, rather than one or ten.**
    * A per-match leaderboard showing the top scores on each match (server). It gives new and existing players a record to try to break. Three is the right number because each match currently has about 15 sessions, and that number will grow. Top 10 would include about two thirds of a match's sessions, so nearly everyone would make it. Top 1 is too exclusive, since a single record is out of reach for most players and gives them little reason to try. Top 3 is about the top 20% today, which is on the generous side, but as the platform grows that share will shrink while still feeling achievable.

2. **What would a large month-over-month change mean in your domain, and what should someone do about it?**
    * It depends on the metric that is changing. If the failure rate rises month over month, the cause needs to be investigated immediately. Currently there are some months with spikes in failures, such as June, which the server teams should investigate in the logs to find the root cause. It is not a sustained month-over-month rise, so I don't think it is detrimental to the platform yet, but it should still be taken seriously. With only 11 to 21 sessions a month, a change of 2 or 3 failures can swing the percentage by over 100%, so the failure counts should be checked alongside the % change before acting. Ideally the failure rate would decline month over month and then plateau. Once that happens, we can start trying to bring more traffic onto the platform. Session volume is currently stagnant, and it would be better to see it grow, but promoting the platform before it is stable is a good way to lose the trust of the player base.

# Reflection

Window functions are most useful when a report needs every row to keep its own detail while also seeing the rows around it without collapsing the data. Doing the same with other methods is much more complicated and cumbersome. Take for example the question: **Which sessions set a new personal best for a player at the time, and by how much did they beat their previous best?** This is easy with a window function. The query selects the player's name, join time and score, and uses `MAX(score)` partitioned by player and ordered by `joined_at`, with a frame that ends at the previous row, to find the best score before each session. Using a CTE, an outer query then keeps only the sessions that scored higher than that previous best. GROUP BY alone cannot answer this. `MAX(score)` grouped by player collapses each player's sessions into one row and returns only their all-time best, losing when it was set, how many times the record was broken and by how much. Rebuilding that without a window function would need a correlated subquery or self-join for every session, which gets confusing. The window version also shows the interesting cases, such as Player_19's +56 jump in October, which is worth checking against the game logs for cheating.
