# Task 6.4: The Closing Memo


### Is it getting better or worse?

The failure problem is **getting better**. The share of sessions that failed fell in every quarter of 2023, from 18.9% in Q1 to 10.4% in Q4 ([q6_2.sql](../queries/unit6/q6_2.sql), Part B: `qtr_running_failed_sessions` and `qtr_running_sessions` on the last day of each quarter).

A failure here uses the same definition as Unit 4: a session dropped by a **network timeout, server restart or client crash**. Players who chose to quit are not counted.

| Quarter | Sessions | Technical failures | Failure rate | Change |
|---|---|---|---|---|
| Q1 | 53 | 10 | 18.9% | – |
| Q2 | 48 | 6 | 12.5% | -6.4 pts |
| Q3 | 51 | 6 | 11.8% | -0.7 pts |
| Q4 | 48 | 5 | 10.4% | -1.4 pts |

The month-over-month view ([q6_3.sql](../queries/unit6/q6_3.sql), Part B) swings sharply. April had no failures at all, June rose 70% over May, and December rose 162.5% over November. Those spikes are worth checking, but the quarterly trend is smoother.

Sessions held steady at 48 to 53 a quarter ([q6_2.sql](../queries/unit6/q6_2.sql), Part B) against a target of 50. After 21 sessions in each of January and February, no month got back to that level ([q6_3.sql](../queries/unit6/q6_3.sql), Part B) which indicates a lack of growth on the platform.

### What the team should do next quarter

1. **APAC server team: fix Matches 11 and 2 before anything else.**
    * *Evidence:* 
        Among the busy matches, these two APAC servers had the highest failure rates in Unit 4, at 25% each, about double the 12% baseline ([q4_2.sql](../queries/unit4/q4_2.sql), Parts A and C). Unit 4 found most abandoned players were on APAC servers ([q4_1.sql](../queries/unit4/q4_1.sql), 4.1.4). In Unit 6, Match 11 went 89 days with no sessions at all, and the sessions on both sides of that gap failed ([q6_2.sql](../queries/unit6/q6_2.sql), Part C). The Unit 5 incident view shows a server restart (March 4th) and a network timeout (March 7th) before the gap, and two client crashes (June 4th and 10th) after it ([q5_1.sql](../queries/unit5/q5_1.sql), Q1). This suggests the server was taken offline and brought back before the error was fixed.
    * *Action:* Pull Match 11's logs for March to June. Add a rule that any server with 2 failed sessions in a row is investigated before it takes new players. The same `LAG` comparison used in [q6_2.sql](../queries/unit6/q6_2.sql) (Part C) can check each session against the one before it and raise that alert.

2. **Hold off on growth campaigns until APAC is fixed.**
    * *Evidence:* 
        Quarterly session volumes are flat, between 48 and 53 ([q6_2.sql](../queries/unit6/q6_2.sql), Part B), and no month got back to January and February's 21 sessions ([q6_3.sql](../queries/unit6/q6_3.sql), Part B).
    * *Action:* Growing volume matters, but bringing new players onto servers that still drop 1 in 10 sessions is not a good first experience. Start a growth campaign after fixing APAC.

3. **Engineering: fix the match records before the next review.**
    * *Evidence:* 
        Only one match's recorded player count agrees with its recorded sessions ([q5_2.sql](../queries/unit5/q5_2.sql), Part A). Matches 14 and 15 have no sessions at all ([q5_2.sql](../queries/unit5/q5_2.sql), Part C) and no game mode assigned ([q5_1.sql](../queries/unit5/q5_1.sql), Q2).
    * *Action:* Perform code review of updating code for matches.player_count to determine root cause of mismatch between match_participants count and matches.player_count. Additionally, determine if matches 14 and 15 need updating or removal.

### Limits of this analysis

The data covers one year and 200 sessions, with 5 to 10 failures per quarter. One extra failure in a quarter moves the rate by about 2 points. The downward trend is consistent across all four quarters, but it should be confirmed against next quarter's data before it is treated as settled.
