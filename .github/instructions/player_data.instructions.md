# Player Data System Documentation

This document explains the completely redesigned player data system for Find The Brainrots, which has been rebuilt from the ground up to support the game's match-based mechanics.

## Overview

The player data system tracks comprehensive statistics, match state, player preferences, and progression for the Find The Brainrots game. It supports both investigador and brainrot roles with detailed analytics.

## Data Structure

### Core Player Information
- `player_level`: Current player level (increases with XP)
- `experience_points`: XP towards next level
- `coins`: In-game currency for purchasing cosmetics

### Task System
- `tasks_completed`: Dictionary of completed tasks (task_id -> boolean)

### Match Statistics (`statistics`)

#### General Statistics
- `matches_played`: Total matches participated in
- `matches_won`: Total matches won
- `total_playtime`: Total time spent in matches (seconds)

#### Investigador Statistics
- `investigador_matches`: Matches played as investigador
- `investigador_wins`: Matches won as investigador
- `correct_kills`: Successful kills of brainrot players
- `incorrect_kills`: Failed kills (NPCs killed)
- `chances_used`: Total investigador chances consumed
- `perfect_games`: Matches won without losing any chances

#### Brainrot Statistics
- `brainrot_matches`: Matches played as brainrot
- `brainrot_wins`: Matches won as brainrot
- `times_discovered`: Times caught by investigadors
- `survival_time`: Total survival time across all brainrot matches

#### Achievement Tracking
- `longest_survival`: Longest single match survival time
- `fastest_win`: Fastest match completion as investigador
- `streak_best`: Best consecutive win streak
- `streak_current`: Current win streak

### Current Match Data (`current_match`)
- `match_id`: Current match identifier (nil if not in match)
- `role`: Current role ("investigador", "brainrot", or "spectator")
- `match_start_time`: When the current match started (os.clock())
- `chances_remaining`: Remaining chances for investigadors
- `kills_this_match`: Kills in current match
- `deaths_this_match`: Deaths in current match
- `is_alive`: Current alive status
- `tasks_completed`: Tasks completed in current match
- `current_zone`: Current zone player is in

### Player Settings (`settings`)

#### UI Preferences
- `show_debug_info`: Show debug information overlay
- `sound_enabled`: Master sound toggle
- `music_volume`: Background music volume (0-1)
- `sfx_volume`: Sound effects volume (0-1)

#### Gameplay Preferences
- `auto_sprint`: Automatically sprint when moving
- `camera_sensitivity`: Mouse/camera sensitivity multiplier
- `fov`: Field of view setting

#### Accessibility
- `color_blind_mode`: Color blind friendly mode
- `reduce_motion`: Reduce motion effects
- `high_contrast`: High contrast mode

### Unlocked Content (`unlocks`)

#### Cosmetic Unlocks
- `character_skins`: Unlocked character appearances
- `emotes`: Unlocked emote animations
- `victory_poses`: Unlocked victory celebrations

#### Gameplay Unlocks
- `game_modes`: Available game modes
- `maps`: Available maps

### Premium Features (`gamepasses`)
- Empty table reserved for future gamepass features

### Timestamps
- `first_joined`: When player first joined (Unix timestamp)
- `last_played`: Last play session (Unix timestamp)
- `total_play_sessions`: Number of times player has joined

## API Functions

### Core Functions

#### `data.player(player: Player): skilift.Session<PlayerData>`
Gets the player's data session. Waits for data to load if necessary.

#### `data.start_match(player: Player, match_id: string, role: PlayerRole): ()`
Initializes player data for a new match.

#### `data.end_match(player: Player, won: boolean): ()`
Processes match completion, updates statistics, calculates XP, and resets match state.

#### `data.record_kill(player: Player, target_type: "player" | "npc", was_correct: boolean): ()`
Records a kill event and updates relevant statistics.

#### `data.record_death(player: Player): ()`
Records a death event and updates statistics.

### Utility Functions

#### `data.complete_task(player: Player, task_id: string?): ()`
Increments task completion counter for current match and optionally marks a specific task as completed.

#### `data.is_task_completed(player: Player, task_id: string): boolean`
Checks if a specific task has been completed by the player.

#### `data.get_completed_tasks(player: Player): {[string]: boolean}`
Returns all completed tasks for the player.

#### `data.reset_task_progress(player: Player): ()`
Resets all task completion progress for the player.

#### `data.update_zone(player: Player, zone_id: string?): ()`
Updates the player's current zone.

#### `data.update_settings(player: Player, new_settings: PlayerSettings): ()`
Updates player preferences and settings.

#### `data.add_coins(player: Player, amount: number): ()`
Adds coins to player's account.

#### `data.unlock_content(player: Player, content_type, content_id: string): ()`
Unlocks cosmetic or gameplay content for the player.

## Usage Examples

### Starting a Match
```lua
local data = require(ReplicatedStorage.Server.Data)

-- Assign player as investigador
data.start_match(player, "match_123", "investigador")

-- Assign player as brainrot
data.start_match(player, "match_123", "brainrot")
```

### Recording Game Events
```lua
-- Player kills an NPC (investigador loses a chance)
data.record_kill(player, "npc", false)

-- Player kills a brainrot player (correct kill)
data.record_kill(player, "player", true)

-- Player dies
data.record_death(player)

-- Player completes a task with specific ID
data.complete_task(player, "collect_evidence_1")

-- Player completes a generic task (no specific ID)
data.complete_task(player, nil)

-- Check if player completed a specific task
local completed = data.is_task_completed(player, "collect_evidence_1")

-- Get all completed tasks
local all_completed = data.get_completed_tasks(player)

-- Reset all task progress
data.reset_task_progress(player)
```

### Ending a Match
```lua
-- Investigadors won
data.end_match(player, true)

-- Brainrots won
data.end_match(player, false)
```

### Accessing Player Data
```lua
local session = data.player(player)
local player_data = session.cached.data

-- Check player's role
if player_data.current_match.role == "investigador" then
    print("Player is an investigador with", player_data.current_match.chances_remaining, "chances")
end

-- Check player's level
print("Player level:", player_data.player_level)
print("XP:", player_data.experience_points)
```

## Experience and Leveling System

### XP Calculation
- **Base XP**: 10 points per match
- **Win Bonus**: +15 points for winning
- **Performance Bonus**: +5 points per kill
- **Gamepass Multiplier**: Currently 1.0x (no gamepass bonuses implemented)

### Level Progression
- **XP Required**: Level × 100 (Level 1 = 100 XP, Level 2 = 200 XP, etc.)
- **Level Up**: Automatic when sufficient XP is gained
- **Overflow**: Excess XP carries over to next level

## Data Migrations

The system includes automatic data migration support through Skilift. When updating the data structure:

1. Add migration functions to the `migrations` array in the store configuration
2. Increment the migration version
3. The system will automatically apply migrations to existing player data

## Performance Considerations

1. **Caching**: Player data is cached in memory for fast access
2. **Batch Updates**: Multiple data changes are batched into single updates
3. **Lazy Loading**: Data is only loaded when needed
4. **Auto-save**: Changes are automatically saved at regular intervals

## Security Features

1. **Server Authority**: All critical game data is server-controlled
2. **GDPR Compliance**: User ID tracking for data deletion requests
3. **Data Validation**: Input validation on all data modifications
4. **Rate Limiting**: Built-in protection against data spam

## Integration with Networking

The player data system integrates seamlessly with the Blink networking system:

```lua
-- Example: Send player statistics to client
local blink = require(ReplicatedStorage.Packages.blink)
local session = data.player(player)
local stats = session.cached.data.statistics

blink.PlayerStatsUpdated.Fire(player, {
    player_id = tostring(player.UserId),
    kills = stats.correct_kills,
    deaths = session.cached.data.current_match.deaths_this_match,
    -- ... other stats
})
```

## Common Patterns

### Checking Match State
```lua
local function is_player_in_match(player: Player): boolean
    local session = data.player(player)
    return session.cached.data.current_match.match_id ~= nil
end
```

### Getting Win Rate
```lua
local function get_win_rate(player: Player): number
    local session = data.player(player)
    local stats = session.cached.data.statistics
    
    if stats.matches_played == 0 then
        return 0
    end
    
    return stats.matches_won / stats.matches_played
end
```

### Checking Unlocks
```lua
local function has_skin_unlocked(player: Player, skin_id: string): boolean
    local session = data.player(player)
    local unlocks = session.cached.data.unlocks.character_skins
    
    return unlocks[skin_id] == true
end
```

This comprehensive player data system provides everything needed to track player progression, match statistics, and game state for the Find The Brainrots game.
