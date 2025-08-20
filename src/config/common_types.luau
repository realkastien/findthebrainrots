--!strict
-- Common types for the Find The Brainrots game
-- This file defines types that are shared across the game

export type PlayerRole = "investigador" | "brainrot" | "spectator"

export type MatchState = "lobby" | "countdown" | "playing" | "ended"

export type GameMode = "standard" | "quick_match" | "ranked" | "custom"

export type ZoneType = "safe" | "restricted" | "danger" | "neutral"

export type TaskType = "collect" | "survive" | "investigate" | "sabotage" | "repair"

export type KillResult = {
    killer_id: string,
    target_id: string,
    target_type: "player" | "npc",
    was_correct: boolean,
    position: Vector3?,
    timestamp: number,
}

export type MatchConfig = {
    duration: number, -- in seconds
    max_players: number,
    investigador_count: number,
    npc_count: number,
    map_name: string,
    game_mode: GameMode,
}

export type PlayerMatchData = {
    player_id: string,
    role: PlayerRole,
    kills: number,
    deaths: number,
    survival_time: number,
    tasks_completed: number,
    is_alive: boolean,
}

export type MatchResult = {
    match_id: string,
    winning_team: "investigadors" | "brainrots" | "draw",
    duration: number,
    players: {[string]: PlayerMatchData},
    config: MatchConfig,
}

return {}