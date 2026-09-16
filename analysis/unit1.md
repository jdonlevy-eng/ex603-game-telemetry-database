## Modeling Justification

Modeling this system involved several key design decisions. The overall structure separates 
descriptive data from high-volume gameplay event data. The `players` and `game_modes` relations 
contain relatively stable descriptive information, while `matches`, `match_participants`, 
`match_modes`, and `scores` capture gameplay event activity. This separation keeps frequently 
generated telemetry data from being mixed with descriptive information and allowing for 
a future data-retention policy.

For primary keys, `players`, `matches`, `game_modes`, and `scores` use system-generated 
surrogate keys. Although username and `game_mode`.`name` could potentially serve as natural keys, 
they are attributes that may change over time. Using surrogate keys means that changing a 
player's username or a game mode's name does not break any referential integratiy. 
`match_participants` also uses a system-generated surrogate key. A composite key of 
(`match_id`, `player_id`) was initially considered, but it would not support a player 
leaving and subsequently rejoining the same match as a separate participation event. A 
new participation record allows attributes such as `kills`, `deaths`, `assists`, and `score` 
to reset while preserving the history of both participation events. This information 
could also provide useful data for evaluating matchmaking behavior. In contrast, 
match_modes uses a composite key of (`match_id`, `game_mode_id`) because the same match 
should have at most one record for a particular game mode.

The `scores` relation was an addition over the original 5 roles in the assignment. 
It was necessary to represent individual scoring events rather than 
expanding `match_participants` with repeated or unrelated scoring attributes. A player
will generate multiple scoring events (hopefully) during a match, and each event may have its 
own `weapon`, `points`, and `score_type`. Separating these events into `scores` avoids 
repeating columns or creating multiple match_participants records solely to represent 
scoring activity.

Several domain restrictions are enforced directly in the schema rather than being left 
entirely to the application. Attributes are generally defined as NOT NULL unless 
implicitly implied by PK, FK. Gameplay counters such as `kills`, `deaths`, 
`assists`, and `score` default to 0, while match_status defaults to `in_lobby`. In contrast, 
`matches`.`ended_at` permits NULL because a match has not ended when it is initially created, 
and `scores`.`weapon` permits NULL because some scoring events may not involve a weapon, 
such as capturing an objective. A check constraint also ensures that a match cannot have 
an ended_at value earlier than its started_at value. Since these are 2 datetime fields
it is resoneable to think the application could, in some instances, swap them.

Foreign keys use ON DELETE behaviors based on the expected lifecycle of the referenced data. 
High-volume event relations such as `matches`, `match_participants`, `scores`, and `match_modes` 
use cascading deletion so that, if a match is intentionally removed as part of a future retention 
policy, its dependent telemetry is removed with it. In contrast, `players` and `game_modes` use 
restrictive deletion behavior. These relations represent reusable descriptive data and should 
not be accidentally deleted while dependent historical records exist. Requiring dependent 
records to be handled explicitly provides an additional safeguard against unintended data loss.
Additionally these relations won' grow as quickly as the other relations so performance
management won't be as important.
 
## Reflection
One decision I made that another designer could reasonably have made differently was separating 
individual scoring events into the `scores` relation rather than keeping them within `match_participants`. 
A different design could treat each scoring event as another match_participants row and use a primary 
key that uniquely identifies a scoring event for a player within a match. While this would be possible, 
I chose to separate scoring events because of the expected read and write patterns of a telemetry system.

During gameplay, a player will generate many scoring events within a single match. Separating these events 
means each event can be written independently to scores without repeatedly duplicating the participant's 
other attributes. This is particularly useful for a high-volume telemetry workload where scoring events 
may be generated frequently. It also makes analytical queries more straightforward because `match_participants`
represents the relatively stable relationship between a player and a match, while scores represents the 
individual events that occurred during that participation.

Keeping both concepts in the same relation would make reads for participant-level statistics more 
complicated because multiple rows could represent the same player-match relationship. It could also 
require repeated data or additional aggregation to reconstruct that relationship. This choice better
represents the analytical needs of the system.