# Task 5.1: Connect Producers to Their Data

### 1. What report on the platform could use the 3-table join in unit5/q5_1.sql query 1?

The join could be used in a match incident report. Support staff could view a failing match and see which players dropped out, when they joined and left, why their session ended (the disconnect reason), which server region hosted the match, and whether each player connected from a different region.

### 2. Why is the junction table match_modes important for finding trends between failed matches and game modes?

A match can offer several game modes, and a game mode can be used by many matches. This is a many-to-many relationship. The match_modes junction table records each match–mode pairing as its own row. This lets Question 2 join matches to game modes and group the results by mode.

Without it, the modes would have to be stored on the matches table, either as a comma-separated list in a single column or as one column per mode. A comma-separated list breaks atomicity, which is poor design. One column per mode means adding a column every time a new mode is released, and grouping by mode would mean checking every column separately. In either case, the simple "group by mode and list its matches" query in Question 2 would no longer be possible.

# Task 5.2: Find Records That Joins May Exclude

### Part A: Compare INNER JOIN and LEFT JOIN

In the previous assignment, some matches were found to have conflicting counts between the matches.player_count column and the actual number of rows in match_participants. Here we take this a step further and check the count for every match using both a LEFT JOIN and an INNER JOIN.

The query results show that the INNER JOIN version of the query silently drops 2 matches, 14 and 15, which both have no rows in match_participants. Query 3 confirms this by counting unique match IDs: the LEFT JOIN returns 15 matches and the INNER JOIN returns 13, so **2 matches are excluded by the INNER JOIN**. This is because an INNER JOIN only returns rows where the join condition finds a match in both the left and right tables. Of the two, the LEFT JOIN is the better choice for this check.

Both queries also show that matches.player_count is not reliable. Matches 14 and 15 have no rows in match_participants, yet matches.player_count states 8 and 6 players respectively. In fact, only one match's player count agrees with its number of rows in match_participants: match 2, with 16. The DISTINCT count in match_participants covers the case where players re-join after leaving, and by that measure no match agrees (match 2 has 13 distinct players). It is not specified whether matches.player_count is meant to be a distinct player count or a count or players connection events.

### Part B: Explore RIGHT JOIN and FULL OUTER JOIN

In Part B of unit5/q5_2.sql, the LEFT JOIN from Part A was rewritten as a RIGHT JOIN. Unsurprisingly, the results were identical, since a RIGHT JOIN only changes which table is treated as the left or right side. Simply swapping the table references creates an equivalent query. Rather than assume this, query 2 in Part B checks it with EXCEPT (set difference) in both directions, both return 0 rows, confirming the two joins return exactly the same records.

What is more interesting is what a FULL OUTER JOIN can show, since it keeps all rows from both sides. A LEFT (or RIGHT) JOIN can identify matches with no match_participants, but a FULL OUTER JOIN can show this as well as match_participants with no match. In this case the results were identical to the LEFT JOIN, meaning there were no match_participants.match_id values that were not represented in matches. That is guaranteed rather than lucky: the foreign key on match_participants.match_id prevents a participation from referencing a match that doesn't exist. A FULL OUTER JOIN earns its place when comparing sources without that guarantee, such as imported data or tables without foreign keys. FULL OUTER JOIN is the best choice for exploratory work like this, where we are checking whether player counts agree between two sources of unknown accuracy.

### Part C: Find Producers with No Events Using Two Approaches

Both queries return matches 14 and 15. NOT EXISTS filters rows of matches and can return any of its columns, while EXCEPT subtracts one set of rows from another, so both sides must have the same columns.

EXCEPT and NOT EXISTS are two approaches for finding matches with no match_participants, both can be found in Part C of unit5/q5_2.sql. Although they identified the same matches, they have several differences. First, and most obvious from the queries, NOT EXISTS lets you select any column available in the outer table. This can be useful when exploring trends, in our example we included server_region, is_ranked and match_code to see whether there was any meaningful connection. This is not possible with EXCEPT, since it is a set difference operator: both SELECT lists must have the same number of columns with compatible types, so any extra column would also have to exist in match_participants. A less obvious difference, which is not well represented in our example, is how duplicates are handled. NOT EXISTS returns every qualifying row from the outer table, duplicates included, while EXCEPT always returns distinct rows, again because it is a set operator. In general, EXCEPT is good for quick checks on key columns that will likely need further queries to dig deeper, whereas NOT EXISTS can answer the question in a single, more complete query that explains where data may be missing.

## Write Up

1. Which producers were excluded by the inner join?
    * Matches 14 and 15 were missing from the inner join but present in the other joins (see Part A).
2. What does it mean when a producer has no events? What are some possible explanations?
    * It could mean that the match never began, perhaps not enough players were available to be matched together, or the host server restarted before players could enter the lobby. Neither match has a game mode assigned in match_modes, which may mean they were never fully configured and so could not start. It is odd that the player_count column shows a non-zero value for these matches, however, as shown in Part A, this is not a reliable field. The data only shows that no participation was recorded, it cannot tell us why, so these explanations would need to be checked against the server logs.
3. How could a report based only on an inner join give leadership an incomplete picture of the platform?
    * Since the inner join queries silently dropped matches 14 and 15, a report generated from them would not give a complete picture. In our case there are only 2 such matches. They are in different server regions, although neither has a game mode assigned (see Q2). Now imagine a scenario where there were 10 matches all from the same server region. That would suggest the region's server needs to be investigated to find the root cause. Without these rows, that server's issues would go unnoticed.
4. Why might leadership want to identify producers who have never been active?
    * Matches that never start are a different problem from ones that start and fail. It may point to a matchmaking or setup fault. Reports that show the failure rate of players dropping out during a game would not include this scenario, since a match with no players cannot have a failure rate.
5. What action could leadership take based on these findings?
    * Leadership could ask the server teams to investigate matchmaking logs and server logs for matches 14 and 15 to determine why they never started. Additionally, they might be able to explain the mismatch between the player_count claimed by the matches table and the participations actually recorded.