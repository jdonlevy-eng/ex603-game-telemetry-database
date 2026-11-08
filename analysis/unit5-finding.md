# Task 5.4: Recommendations

### Summary

Two different problems show up in the match data, and they need different responses. Some matches **start but fail often**: players get into the match and are then dropped by a technical fault. Other matches **never started at all**: they are on the schedule, but no one ever played in them. The first is a reliability problem to fix. The second is a setup problem to trace and prevent.

### Matches that fail often (Matches 2, 11 and 9) - Flagged in assignment 4

**What the data shows**

- **Match 2 (APAC)** and **Match 11 (APAC):** 1 in 4 players were dropped by a technical failure (25%), about double the platform's typical rate of 12%. Most of Match 2's failures are network timeouts. Match 11's are a mix of game crashes, a timeout and a server restart.
- **Match 9 (EU):** the highest failure rate on the platform (28.6%). Two of its four failures are game crashes on the player's device.
- 10 of the 12 failures across these three matches happened to players connecting from outside the match's server region, for example players in South America joining an APAC match. Across the whole platform, players connecting from another region were dropped about twice as often as players in the same region (15% vs 7.5%).

**Recommended actions**

* **APAC server team (Matches 2 and 11):** review the server and network logs for the times these players were dropped, looking for capacity limits or connection problems affecting players joining from other regions.
* **Game client team (Match 9):** pull the crash reports for the two game crashes in this match to see whether they share a game version or device type. This will tell us whether the crashes can be fixed in the game itself.

**What needs more investigation:** the data shows where and when players were dropped, not why. The cross-region pattern is a strong lead but not a proven cause, since most sessions on the platform are cross-region.

### Group 2: Matches that never started (Matches 14 and 15)

**What the data shows**

- **Match 14** and **Match 15** are scheduled, but no players were ever recorded in them. Because of this, they never appear in failure reports: a match with no players cannot have a failure rate.
- The match records still list 8 and 6 players for these matches. The player count on match records cannot be trusted anywhere on the platform: only one match's figure agrees with the players actually recorded.

**Recommended actions**

* **Live operations team:** check the scheduling and matchmaking logs for Matches 14 and 15 to find out whether they were cancelled, failed to launch, or ran without their players being recorded. The last case would be a record-keeping problem rather than a game problem.

### Why the two groups need different responses

Matches that fail often are a **quality problem**: players are getting in and then being dropped, so the fix lies with the servers or the network. Matches that never started are a **setup problem**: nothing happened at all, so the fix lies with scheduling or setup.
