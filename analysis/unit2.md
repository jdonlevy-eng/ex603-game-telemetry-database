# Unit 2 — Analysis of `schema/schema.sql`

## 1. The constraints table

| Foreign key | ON DELETE | Reason |
|---|---|---|
| `fk_match_id` — `match_participants.match_id` → `matches.match_id` | `CASCADE` | The match_participants contextually depend on the existance of the match |
| `fk_player_id` — `match_participants.player_id` → `players.player_id` | `SET NULL` | The match does not depend contextually on 1 player |
| `fk_match_id` — `match_modes.match_id` → `matches.match_id` | `CASCADE` | Match_modes depends on the match, without it the match_mode is useless |
| `fk_game_mode_id` — `match_modes.game_mode_id` → `game_modes.game_mode_id` | `SET NULL` | Without match_mode, game_mode is useless |
| `fk_match_participant_id` — `scores.match_participant_id` → `match_participants.match_participant_id` | `CASCADE` | Scores can only exist in the context of a match_participant |

### Discussion of ON DELETE choices

#### `match_participants.match_id` → `matches` (CASCADE)

**The event:** To set context we need to remember the purpose of this platform is to gain insights about gameplay. It is reasonable to assume the match data won't be kept forever for performance reasons or perhaps we consider that data is out of date, for instance when a new game version is released we may start analysis over. When this happens we purge at least some of the matches.

**Who or what is affected:** As a result of match deletion the match_participant data is no longer of any use. It is only in the context of a match that data is relevant. It should be deleted too

**Under the alternative:** If the ON DELETE behavior were RESTRICT, the system would grow without check and would encounter performance issues or exceed budget for server costs. If the behavior were to be set null, the match_participants would need to be deleted seperately which is a maintnance item that is not required.

#### `match_participants.player_id` → `players` (SET NULL)

**The event:** This ON DELETE behavior should not be excersized. A players account should only ever be soft deleted (set status to inactive) to prevserve that match_participant data. However if players grows too large it may be a good stategy to delete some inactive users.

**Who or what is affected:** When a player is deleted the match_participant table should set null because that players match data contributed to a team.

**Under the alternative:** If set to CASCADE aggregate team data would be impossible such as a teams total score for a given match. RESTRICT could work but wouldn't allow the flexiblility for a dba to manage the player table size.

#### `match_modes.match_id` → `matches` (CASCADE)

**The event:** Matches are deleted as part of maintnenance as discusses previously.

**Who or what is affected:** When matches are deleted match_mode is no longer relevant. We would never need to know about match_modes outside the context of a match

**Under the alternative:** SET NULL or RESTRICT would allow data with no meaning to take up space in the db.

#### `match_modes.game_mode_id` → `game_modes` (CASCADE)

**The event:** When a game_mode is removed from availability, perhaps a depreciated mode.

**Who or what is affected:** Without 1 part of a composite key there is no value to this weak table. It has no columns of its own. Its sole purpose is to resolve the m:n relationship between matches and modes. Without the mode it is useless.

**Under the alternative:** SET NULL or RESTRICT would allow data with no meaning to take up space in the db.

#### `scores.match_participant_id` → `match_participants` (CASCADE)

**The event:** Matches are deleted as maintanence activity as described above.

**Who or what is affected:** For the same reasons that match_participants are no longer relevant without the context of a match the score is irrelevant without the context of a match_participant. It provides no contex value.

**Under the alternative:** SET NULL or RESTRICT would allow data with no meaning to take up space in the db.

## 2. The CHECK constraints


### `players`

#### `chk_region_values` — `region IN ('NA','LATAM','EU','MENA','AF','SA','SEA','EA','OCE')`

**Invalid state prevented:** Enforces only specific regional values

**How it could otherwise arise:** Prevents different platforms from sending data that conform to this list

#### `chk_platform_values` — `platform IN ('Xbox','Playstation','PC','Mobile')`

**Invalid state prevented:** Enforces only certain gaming platforms to write to the telemetry system

**How it could otherwise arise:** Prevents other platforms that perhaps have not been tested in the platform, or errors in naming

#### `chk_status_values` — `status IN ('active','banned','inactive')`

**Invalid state prevented:** Enforces only valid account states

**How it could otherwise arise:** Prevents ambiguitiy in the field, which leads to difficulty grouping by the field

### `matches`

#### `chk_server_region_values` — `server_region IN (...)`

**Invalid state prevented:** Ensures server region matches the same valid values as the players region

**How it could otherwise arise:** Prevents errors or mispelling proliferating through the db.

#### `chk_match_status_values` — `match_status IN ('MATCHMAKING','LOBBY','IN_PROGRESS','CANCELLED','COMPLETE')`

**Invalid state prevented:** Enforces only specific match status

**How it could otherwise arise:** Prevents unkown match status from entering the db.

#### `ended_after_started` — `ended_at IS NULL OR ended_at >= started_at`

**Invalid state prevented:** Ensures the end timestamp of a match occurs after the start timestamp

**How it could otherwise arise:** Prevents a negative duration from being computed

### `game_modes`

#### `chk_name_values` — `name IN ('TEAM_DEATHMATCH','CAPTURE_THE_FLAG','SEARCH_AND_DESTROY','DOMINATION')`

**Invalid state prevented:** Enforces only the game modes that are offered

**How it could otherwise arise:** Prevents new game modes from entering without proper testing

#### `chk_max_players_between` — `max_players > 2 AND max_players < 20`

**Invalid state prevented:** Ensures data consistency in matches. There are 2 teams for any game which requires at least 1 player per team. No game modes offer more than 10 per team (20)

**How it could otherwise arise:** Bad platform code could lead to incorrect player counts

#### `chk_min_players_between` — `min_players > 2 AND min_players < 20`

**Invalid state prevented:** Similar to max_players, this check enforces the data makes sense

**How it could otherwise arise:** Similar to max_player this prevents bad code leading to incorrect player counts

### `match_participants`

#### `chk_team_name_values` — `team_name IN ('TERMINATORS','HUMANS')`

**Invalid state prevented:** Prevents an unkown team name from entering the DB

**How it could otherwise arise:** There is no valid reason this would arise other than in error

#### `chk_character_values` — `character IN ('T-800', ..., 'Resistance Technician')`

**Invalid state prevented:** Prevents unknown character choices from entering the db

**How it could otherwise arise:** There is no valid reason this would arise other than in error

#### `chk_kills_pos` — `kills >= 0`

**Invalid state prevented:** Ensures kill count is positive (or 0)

**How it could otherwise arise:** If a bad update tried to send a negative kill

#### `chk_assists_pos` — `assists >= 0`

**Invalid state prevented:** Ensures assist count is positive (or 0)

**How it could otherwise arise:** If a bad update tried to send a negative assist

#### `chk_deaths_pos` — `deaths >= 0`

**Invalid state prevented:** Ensures death count is positive (or 0)

**How it could otherwise arise:** If a bad update tried to send a negative death

#### `chk_result_values` — `result IN ('WIN','LOSS')`

**Invalid state prevented:** Prevents any alternative result to a match (like 'Forfiet' which should be win)

**How it could otherwise arise:** If a bad update tried to send a result no included in the list

### `scores`

#### `chk_score_type_values` — `score_type IN ('Kill', 'Assist', ..., 'Match Victory')`

**Invalid state prevented:** Ensures score types are belong to a known list

**How it could otherwise arise:** If a bad update tried to send an unknown score type

#### `chk_points_pos` — `points > 0`

**Invalid state prevented:** Ensures points are positive

**How it could otherwise arise:** If a bad update tried to send a negative point value