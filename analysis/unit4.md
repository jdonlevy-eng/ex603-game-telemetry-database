# Task 4.1: Measure the breakdown

### Name the person who would act on the per-producer breakdown

The person who would act on the per-match breakdown is whomever is responsible for the APAC and OCE servers, as the last query we ran in task 4.1 identified these servers with the highest rate of abandoned players. Server logs
can be review to determine if there is a capacity, or perhaps application issue.

### What the aggregates hide

- **The zeros drag the average down.** Every abandoned event is recorded with a score of 0. Match 11 averages 11.94 points, but its players who actually stayed in the match averaged 17.37. It doesn't show that players perform worse.
- **A player can have multiple participation records in a match** Match 6's 21 match_participants come from only 14 different players. Across the platform, 200 events come from just 30 players. Error rates for 1 particular player should not weight down the entire stat
- **Inconsistency between matches and match_participants** Matches 14 and 15 exist in `matches` but have no `match_participants`, so they never appear in a `GROUP BY` on the event table. The breakdown can't show a match with miss data. Additionally the matches that are represented in `match_participants` dont have a `COUNT` that correlate the `matches.player_count`. For example matchid 6 has count of 21 (4 of which abandoned) and matches shows `player_count` of 4


# Task 4.2: Build the breakdown leadership asked for

### Part A: Answers what questions
- Each row represents a unique match and the columns answer the question of how many abandoned participants experienced a failure event (network timeout,server restart,client crash) as well as if any of those counts happened mulitple times in the match for any participants.

### Part B: Identify who needs subtotals
- The reader who needs the subtotals would be whomever is responsible for the management of all regional servers. The subtotals provide insight into the performance of the matches on a server level. The grand totals help frame the subtotals as percentages of what may above or below average failure rate. Decision on whether to investigate high failure regional servers depend on the comparison against the totals.

### Part C: The Pipeline
- The pipeline query in part c helps to frame the performance of matches against the pipeline/baseline. It can help answer questions like **Is the failure rate of a particular match far above average?** or **Is the average score in a particular match consistent with averages across all matches**. The answers to these question help identify potential issue and can be used in the future as a basis to show trends in platform performance.