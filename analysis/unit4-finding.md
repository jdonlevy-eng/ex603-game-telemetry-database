# Task 4.3: The Finding

## The true failure rate

The dashboard said roughly half of all matches failed. The actual figure is far lower: **27 of 200 player participations (13.5%)** ended in a technical failure. A failure here means a player was dropped from a match by a **network timeout (12)**, a **server restart (8)** or a **client crash (7)**. Players who chose to quit are not counted, because leaving by choice is not a platform failure.

## How it varies across matches

Failures are not spread evenly across matches. Among the eight matches with 15 or more participants, where the numbers are large enough to trust, the typical failure rate is about **12%**. Two of those matches run at roughly double that (2 and 11), and two had no failures at all (8 and 10). Match 9, with 14 participants, falls just below this cutoff but has the highest failure rate on the platform.

## The matches I would investigate

1. **Match 2 (APAC):** 25% failure rate, about double the baseline. Three of its four failures are network timeouts, which suggests a server connection or capacity issue.
2. **Match 11 (APAC):** 25% failure rate, with two client crashes, a network timeout and a server restart. It also has the lowest average score of any match (11.94). Together with Match 2, this makes the APAC servers worth investigating.
3. **Match 9 (EU):** the highest failure rate on the platform (28.6%). Two of its four failures are client crashes. The data at hand cannot tell us whether these client-side crashes are preventable in the game code or caused by players' hardware.

## Caveats

- The data records when a *player* drops out of a match. It does not record whether a *match* as a whole failed, so this is a participation failure rate, not a match failure rate. A match failure rate would need to be defined before it could be reported, but in my opinion the participation failure rate is the more meaningful metric.
- There are only 200 records for 30 players, and some players appear more than once in the same match. A single player who repeatedly drops can push a match's rate up.
- The participant counts in this data do not match the player counts recorded for each match. For example, Match 6 lists 4 players but has 21 participation records. This should be fixed before these figures are used for payouts. Additionally, two matches (14 and 15) have no recorded participants at all. This should also be investigated in the application logs to determine whether data is missing.
