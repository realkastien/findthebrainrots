# Network Events Documentation

This document explains every network event defined in the Find The Brainrots game. Events are organized by category for better understanding.

---

## Custom Types

### PlayerRole
- `role_type`: String indicating "investigador" or "brainrot"
- `chances_remaining`: Optional number of chances left for investigadors

### MatchData
- `match_id`: Unique identifier for the match
- `duration`: Match duration in seconds
- `investigador_count`: Number of investigador players
- `brainrot_count`: Number of brainrot players  
- `npc_count`: Number of NPC brainrots in the match

### PlayerStats
- `player_id`: Unique player identifier
- `kills`: Number of successful kills
- `deaths`: Number of times the player died
- `npcs_killed`: Number of NPCs killed (reduces investigador chances)
- `players_found`: Number of brainrot players successfully identified

### CountdownData
- `duration`: Countdown duration in seconds
- `match_type`: Optional string describing the type of match starting

### TaskData
- `task_id`: Unique task identifier
- `task_type`: Type of task (e.g., "collect", "survive", "investigate")
- `description`: Human-readable task description
- `reward_points`: Optional points awarded for completion

### BrainrotData
- `target_player_id`: ID of the player who was identified as a brainrot
- `finder_player_id`: ID of the investigador who found them
- `position`: Optional position where the discovery occurred

### KillData
- `killer_id`: ID of the player who performed the kill
- `target_id`: ID of the target (player or NPC)
- `target_type`: "player" or "npc"
- `was_correct`: Whether the kill was correct (investigador killing brainrot player)
- `position`: Optional position where the kill occurred

### MatchResult
- `winning_team`: "investigadors" or "brainrots"
- `duration`: Actual match duration
- `final_stats`: Array of all player statistics

---

## Match Management Events

### MatchStarted
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: MatchData

Fired when a new match begins. Contains all essential match information including player counts and match ID.

**Usage**:
```lua
-- Server
blink.MatchStarted.FireAll({
    match_id = "match_123",
    duration = 300,
    investigador_count = 2,
    brainrot_count = 6,
    npc_count = 20
})

-- Client
blink.MatchStarted.On(function(match_data)
    print("Match started:", match_data.match_id)
    ui:ShowMatchInfo(match_data)
end)
```

### MatchEnded
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: MatchResult

Fired when a match concludes. Contains the winning team and final statistics.

**Usage**:
```lua
-- Server
blink.MatchEnded.FireAll({
    winning_team = "investigadors",
    duration = 245,
    final_stats = player_stats_array
})

-- Client
blink.MatchEnded.On(function(result)
    ui:ShowMatchResults(result)
end)
```

### MatchCountdownStarted
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: CountdownData

Fired when a pre-match countdown begins.

**Usage**:
```lua
-- Server
blink.MatchCountdownStarted.FireAll({
    duration = 10,
    match_type = "standard"
})

-- Client
blink.MatchCountdownStarted.On(function(countdown_data)
    ui:StartCountdown(countdown_data.duration)
end)
```

### MatchCountdownCancelled
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (reason)

Fired when a countdown is cancelled before match start.

**Usage**:
```lua
-- Server
blink.MatchCountdownCancelled.FireAll("Not enough players")

-- Client
blink.MatchCountdownCancelled.On(function(reason)
    ui:ShowCancellationMessage(reason)
end)
```

### MatchPaused
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (reason)

Fired when a match is temporarily paused.

### MatchResumed
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (message)

Fired when a paused match is resumed.

---

## Player Role Events

### PlayerRoleAssigned
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: PlayerRole

Sent to a player to inform them of their assigned role at match start.

**Usage**:
```lua
-- Server
blink.PlayerRoleAssigned.Fire(player, {
    role_type = "investigador",
    chances_remaining = 3
})

-- Client
blink.PlayerRoleAssigned.On(function(role_data)
    local_player_role = role_data.role_type
    if role_data.role_type == "investigador" then
        ui:ShowInvestigadorUI(role_data.chances_remaining)
    else
        ui:ShowBrainrotUI()
    end
end)
```

### PlayerRoleChanged
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: PlayerRole

Sent when a player's role changes mid-match (rare, but possible in special game modes).

### InvestigadorChancesUpdated
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: u8 (remaining chances)

Sent to investigadors when their remaining chances change.

**Usage**:
```lua
-- Server
blink.InvestigadorChancesUpdated.Fire(investigador_player, 2)

-- Client (investigador only)
blink.InvestigadorChancesUpdated.On(function(remaining_chances)
    ui:UpdateChancesDisplay(remaining_chances)
    if remaining_chances == 0 then
        ui:ShowGameOverMessage()
    end
end)
```

---

## Player Action Events

### PlayerKillAttempt
**Direction**: Client → Server  
**Type**: Reliable  
**Data**: string (target ID)

Sent when a player attempts to kill another player or NPC.

**Usage**:
```lua
-- Client
local function attempt_kill(target)
    blink.PlayerKillAttempt.Fire(target.UserId)
end

-- Server
blink.PlayerKillAttempt.On(function(player, target_id)
    game_manager:ProcessKillAttempt(player, target_id)
end)
```

### PlayerKilled
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: KillData

Broadcast when a kill occurs, whether successful or not.

**Usage**:
```lua
-- Server
blink.PlayerKilled.FireAll({
    killer_id = killer.UserId,
    target_id = target.UserId,
    target_type = "player",
    was_correct = true,
    position = target.Character.HumanoidRootPart.Position
})

-- Client
blink.PlayerKilled.On(function(kill_data)
    ui:ShowKillFeedback(kill_data)
    if kill_data.target_id == Players.LocalPlayer.UserId then
        ui:ShowDeathScreen()
    end
end)
```

### BrainrotFound
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: BrainrotData

Broadcast when an investigador successfully identifies a brainrot player.

**Usage**:
```lua
-- Server
blink.BrainrotFound.FireAll({
    target_player_id = brainrot_player.UserId,
    finder_player_id = investigador_player.UserId,
    position = brainrot_player.Character.HumanoidRootPart.Position
})

-- Client
blink.BrainrotFound.On(function(brainrot_data)
    ui:ShowBrainrotFoundMessage(brainrot_data.finder_player_id, brainrot_data.target_player_id)
end)
```

### PlayerEliminated
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, string) - player_id, reason

Broadcast when a player is eliminated from the match.

### PlayerRevived
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (player_id)

Broadcast when a player is revived (if revival mechanics exist).

---

## Task System Events

### TaskAssigned
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: TaskData

Sent to a player when they receive a new task.

**Usage**:
```lua
-- Server
blink.TaskAssigned.Fire(player, {
    task_id = "collect_evidence_1",
    task_type = "collect",
    description = "Find 3 pieces of evidence around the map",
    reward_points = 100
})

-- Client
blink.TaskAssigned.On(function(task_data)
    task_manager:AddTask(task_data)
    ui:ShowNewTaskNotification(task_data)
end)
```

### TaskFinished
**Direction**: Client → Server  
**Type**: Reliable  
**Data**: string (task_id)

Sent when a player completes a task.

**Usage**:
```lua
-- Client
local function complete_task(task_id)
    blink.TaskFinished.Fire(task_id)
end

-- Server
blink.TaskFinished.On(function(player, task_id)
    task_manager:ProcessTaskCompletion(player, task_id)
end)
```

### TaskCompleted
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, TaskData) - player_id, completed_task

Broadcast when a player successfully completes a task.

### TaskFailed
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: (string, string) - task_id, reason

Sent when a player fails a task.

---

## Game State Events

### GameStateChanged
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (new_state)

Broadcast when the overall game state changes.

**Possible States**:
- "lobby" - Players waiting for match
- "countdown" - Pre-match countdown
- "playing" - Match in progress
- "ended" - Match concluded

### PlayerJoinedMatch
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (player_id)

Broadcast when a new player joins the current match.

### PlayerLeftMatch
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (player_id)

Broadcast when a player leaves the current match.

---

## Communication Events

### ChatMessage
**Direction**: Client → Server  
**Type**: Reliable  
**Data**: string (message)

Sent when a player wants to send a chat message.

### ChatMessageBroadcast
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, string) - player_id, message

Broadcast chat messages to all players.

### SystemMessage
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (system_message)

Broadcast system messages (e.g., game announcements, warnings).

---

## Statistics and Leaderboard Events

### PlayerStatsUpdated
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: PlayerStats

Sent to update a player's personal statistics.

### LeaderboardUpdated
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: PlayerStats[] (sorted leaderboard)

Broadcast updated leaderboard to all players.

---

## Power-ups and Items Events

### PowerUpSpawned
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, vector, string) - item_id, position, item_type

Broadcast when a power-up spawns in the world.

### PowerUpCollected
**Direction**: Client → Server  
**Type**: Reliable  
**Data**: string (item_id)

Sent when a player collects a power-up.

### PowerUpUsed
**Direction**: Client → Server  
**Type**: Reliable  
**Data**: string (item_type)

Sent when a player uses a power-up.

### PowerUpActivated
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, string) - player_id, item_type

Broadcast when a power-up effect is activated.

---

## Zone and Map Events

### ZoneRestricted
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, vector, f32) - zone_id, center_position, radius

Broadcast when an area becomes restricted/dangerous.

### ZoneUnrestricted
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (zone_id)

Broadcast when a restricted zone becomes safe again.

### PlayerEnteredZone
**Direction**: Client → Server  
**Type**: Unreliable  
**Data**: string (zone_id)

Sent when a player enters a specific zone.

### PlayerExitedZone
**Direction**: Client → Server  
**Type**: Unreliable  
**Data**: string (zone_id)

Sent when a player exits a specific zone.

---

## NPC Management Events

### NpcSpawned
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, vector, string) - npc_id, position, npc_type

Broadcast when an NPC brainrot spawns.

### NpcDestroyed
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: string (npc_id)

Broadcast when an NPC is destroyed/killed.

### NpcBehaviorChanged
**Direction**: Server → All Clients  
**Type**: Reliable  
**Data**: (string, string) - npc_id, new_behavior

Broadcast when an NPC's behavior pattern changes.

---

## Error and Debug Events

### GameError
**Direction**: Server → Specific Client  
**Type**: Reliable  
**Data**: string (error_message)

Sent to inform a player of game errors.

### DebugInfo
**Direction**: Server → Specific Client  
**Type**: Unreliable  
**Data**: string (debug_data)

Sent for debugging purposes (development only).

---

## Implementation Tips

1. **Error Handling**: Always wrap event listeners in pcall() to prevent crashes
2. **Rate Limiting**: Be careful with high-frequency events like zone updates
3. **Data Validation**: Validate all incoming data on the server side
4. **Performance**: Use unreliable events for non-critical, frequent updates
5. **Security**: Never trust client data for game-critical decisions

## Example Usage Patterns

### Match Flow
```lua
-- Typical match flow event sequence:
-- 1. MatchCountdownStarted
-- 2. PlayerRoleAssigned (to each player)
-- 3. MatchStarted
-- 4. Various gameplay events...
-- 5. MatchEnded
```

### Kill Sequence
```lua
-- Typical kill sequence:
-- 1. PlayerKillAttempt (client → server)
-- 2. PlayerKilled (server → all clients)
-- 3. InvestigadorChancesUpdated (if investigador killed NPC)
-- 4. PlayerStatsUpdated (to killer)
```

### Task Flow
```lua
-- Typical task flow:
-- 1. TaskAssigned (server → client)
-- 2. TaskFinished (client → server)
-- 3. TaskCompleted (server → all clients)
-- 4. PlayerStatsUpdated (to completing player)
```
