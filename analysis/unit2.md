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

<!-- For each FK answer three things:
     1. The real event: what actually happens on the platform when a row in the parent table is removed?
     2. Who/what is affected by the choice you made?
     3. What would go wrong under the alternative (RESTRICT / NO ACTION, CASCADE, SET NULL)? -->

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