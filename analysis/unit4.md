# Task 4.1: Measure the breakdown

### Name the person who would act on the per-producer breakdown

The person who would act on the per-match breakdown is whoever is responsible for the APAC and OCE servers, as the last query in Task 4.1 showed these servers had the most abandoned players. Their server logs can be reviewed to determine whether there is a capacity or application issue.

### Choosing the volume threshold

For query 4.1.3 I chose a minimum of 15 participants per match. Match sizes range from 6 to 21 participants, with a median of 16, so 15 sits just below the median. It keeps the eight larger matches (145 of the 200 records) and drops the smaller ones, where one or two dropped players can swing the failure rate by 10 percentage points or more.

### What the aggregates hide

- **The zeros drag the average down.** Every abandoned event is recorded with a score of 0. Match 11 averages 11.94 points, but its players who actually stayed in the match averaged 17.37. The low average does not mean its players performed worse.
- **A player can have multiple participation records in a match.** Match 6's 21 participation records come from only 14 different players. Across the platform, 200 events come from just 30 players. Repeated failures for one player should not weigh down the entire statistic.
- **Inconsistency between matches and match_participants.** Matches 14 and 15 exist in `matches` but have no `match_participants`, so they never appear in a `GROUP BY` on the event table. The breakdown can't show a match with missing data. Additionally, the record counts in `match_participants` don't match `matches.player_count`. For example, match 6 has 21 participation records (4 of them abandoned), but `matches` shows a `player_count` of 4.

### What I would need to see next

- **A match-level outcome.** The data only records when an individual player drops out. To report a true match failure rate, matches need a status showing whether the match completed or failed.
- **The score distribution without the zeros.** The median and spread of scores for players who finished, so that abandoned records don't distort the picture of player performance.
- **Failures per unique player.** Counting each player once per match would show whether a few players with repeated drops are inflating a match's failure rate.
- **Server logs for APAC and OCE.** Timestamps of restarts and timeouts would show whether the failures cluster around capacity or deployment events.


# Task 4.2: Build the breakdown leadership asked for

### Part A: Answers what questions
- Each row represents a unique match, and the columns answer two questions side by side: how many participants did the match have, and how many of them experienced a failure? The failures are also broken down by type (network timeout, server restart, client crash). The unique counts also show whether the same player experienced a failure multiple times in one match.

### Part B: Identify who needs subtotals
- The reader who needs the subtotals is whoever manages all of the regional servers. The subtotals show how matches perform at the server-region level. The grand total frames each subtotal against the platform-wide figure, showing whether a region accounts for more than its share of the failures. The decision on whether to investigate a high-failure region depends on that comparison with the grand total.
- **Reading the output:** each row with a region name in `server_region` (APAC, EU, NA, OCE, SA) is a regional subtotal. The row labelled **All server regions** is the platform grand total: 200 participants, with 12 network timeouts, 8 server restarts and 7 client crashes.

### Part C: The Pipeline
- The pipeline answers the question: **What is the typical failure rate and average score for high-volume matches (15 or more participants)?** That baseline lets each match be compared against it, answering questions like **Is the failure rate of a particular match far above average?** or **Is the average score in a particular match consistent with the average across all matches?** The answers help identify potential issues and can be used in the future as a basis for tracking trends in platform performance.

# Task 4.3: Reflection

### Conditional aggregation vs. separate filtered queries

Conditional aggregation answers several questions in one pass. In Part A, a single scan of `match_participants` returned each match's total participant count alongside its network timeout, server restart and client crash counts. Each row is read once, and the `CASE` inside each `COUNT` decides which columns that row adds to. To get a similar result with filtered queries, I would need one query for the totals and another for each failure condition, then join the results by `match_id`. In this example that means four scans instead of one, plus the overhead of the join. A match with no failures of a given type simply disappears from that filtered query, so it has to be added back with a `LEFT JOIN` and `COALESCE` or its count shows up as missing instead of 0.

With only 200 rows, the performance difference is negligible. From professional experience, even at a million rows (small for a production database), a well-indexed database would likely not show a noticeable difference for a report run a few times a quarter. The performance argument becomes stronger when end users run the query often, because every extra scan multiplies the cost (1 scan vs 4 in this case). The bigger benefits are maintainability and consistency: a change is made in one place rather than repeated across several queries, and every column is calculated from the same set of rows.
