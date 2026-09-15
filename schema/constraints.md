# Game Telemetry Database — Constraints

Listed below are the constraints in the Game Telemetry Database

## 1. players

| Attribute           | Constraint(s)              | Justification                                           |
| ------------------- | -------------------------- | ------------------------------------------------------- |
| player_id           | PK, Auto-increment         |                                                         |
| username            | NOT NULL, UNIQUE           |                                                         |
| email               | NOT NULL, UNIQUE           |                                                         |
| region              | NOT NULL                   |                                                         |
| platform            | NOT NULL                   |                                                         |
| status              | NOT NULL, DEFAULT 'ACTIVE' |  All accounts are active on initial creation            |
| created_at          | NOT NULL, DEFAULT NOW      |                                                         |

## 2. matches

| Attribute           | Constraint(s)                   | Justification                                           |
| ------------------- | ------------------------------- | ------------------------------------------------------- |
| match_id            | PK, Auto-increment              |                                                         |
| map_name            | NOT NULL                        |                                                         |
| server_region       | NOT NULL                        |                                                         |
| started_at          | NOT NULL, DEFAULT NOW           |                                                         |
| ended_at            | NOT NULL CHECK > started_at     | Ensure ended_at occurs after started_at                 |
| match_status        | NOT NULL, DEFAULT 'in_lobby'    | All matches begin in the lobby                          |

## 3. match_participants

| Attribute             | Constraint(s)                   | Justification                                           |
| --------------------- | ------------------------------- | ------------------------------------------------------- |
| match_participant_id  | PK, Auto-increment              |                                                         |
| match_id              | FK, ON DELETE CASCADE           | Matches do not need to be retained forever, if 1 is deleted, delete corresponding match participants                                                       |
| player_id             | FK, ON DELETE RESTRICT          | Players should never be deleted, only status mvoed to inactive. This is a safety to avoid deletion                                                        |
| team_id               | NOT NULL           |                                                         |
| character             | NOT NULL|
| joined_at             | NOT NULL DEFAULT NOW            |                 |
| left_at               | NULL                            | Will be null until either end of game or participant quits                         |
| kills                 | NOT NULL, DEFAULT 0
| deaths                | NOT NULL, DEFAULT 0
| assists               | NOT NULL, DEFUALT 0
| result                | NULL | Will populate at games end

## 4. game_modes

| Attribute           | Constraint(s)                   | Justification                                           |
| ------------------- | ------------------------------- | ------------------------------------------------------- |
| game_mode_id            | PK, Auto-increment              |                                                         |
| name            | NOT NULL                        |                                                         |
| description       | NOT NULL                        |                                                         |
| min_players         | NOT NULL, DEFAULT 2           |    At least 1 player per team                                                     |
| max_players            | NOT NULL CHECK >= min_players     | Ensure max_players >= min_players                 |

## 5. match_modes

| Attribute           | Constraint(s)                   | Justification                                           |
| ------------------- | ------------------------------- | ------------------------------------------------------- |
| match_id            | PK, FK, ON DELETE CASCADE       | When matches are deleted match_mode is no longer needed                                                        |
| game_mode_id        | PK, FK, ON DELETE RESTRICT      | If a game mode is deleted the relationship breaks between matches and game modes                                                         |


## 6. score

| Attribute           | Constraint(s)                   | Justification                                           |
| ------------------- | ------------------------------- | ------------------------------------------------------- |
| score_id            | PK, Auto-increment              |                                                         |
| match_participant_id| FK, ON DELETE CASCADE                              | No longer needed when matches are deleted                                                        |
| weapon        | NULL
| score_type          | NOT NULL                        |                                                         |
| points          | NOT NULL           |                                                         |
| scored_at            | NOT NULL, DEFAULT NOW     |                  |