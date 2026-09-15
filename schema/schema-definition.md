# Game Telemetry Database — Relation Schema

Listed below are the relations in the Game Telemetry Database

## 1. players

**players**(player_id, username, email, region, platform, status, created_at)

- player_id: integer
- username: string
- character: string
- email: string
- region: string
- platform: string
- status: string
- created_at: datetime

**Primary Key:** player_id

## 2. matches

**matches**(match_id, map_name, server_region, started_at, ended_at, duration_seconds, match_status)

- match_id: integer
- map_name: string
- server_region: string
- started_at: datetime
- ended_at: datetime
- match_status: string

**Primary Key:** match_id

## 3. match_participants

**match_participants**(match_participant_id, match_id, player_id, team_id, joined_at, left_at, kills, deaths, assists, placement, result)

- match_participant_id: integer
- match_id: integer
- player_id: integer
- team_id: integer
- joined_at: datetime
- left_at: datetime
- kills: integer
- deaths: integer
- assists: integer
- result: string

**Primary Key:** match_participant_id 

## 4. game_modes

**game_modes**(game_mode_id, name, description, team_based, max_players)

- game_mode_id: integer
- name: string
- description: string
- max_players: integer
- min_players: integer

**Primary Key:** game_mode_id

## 5. match_modes

**match_modes**(match_id, game_mode_id, is_primary)

- match_id: integer
- game_mode_id: integer

**Primary Key:** Composite Key match_id + game_mode_id

## 6. score

**score**(score_id, match_participant_id, score_type, points, recorded_at)

- score_id: integer
- match_participant_id: integer
- score_type: string
- weapon : string
- points: integer
- recorded_at: datetime

**Primary Key:** score_id 

