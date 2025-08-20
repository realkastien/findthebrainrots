local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local charm = require(ReplicatedStorage.Packages.charm)
local skilift = require(ReplicatedStorage.Packages.skilift)

export type Transaction = {
	transaction_id: number,
	transaction_type: "Gamepass" | "Product",
	date: number,
	cost: number,
}

export type PlayerRole = "investigador" | "brainrot" | "spectator"

export type MatchStatistics = {
    -- General match stats
    matches_played: number,
    matches_won: number,
    total_playtime: number, -- in seconds
    
    -- Investigador specific stats
    investigador_matches: number,
    investigador_wins: number,
    correct_kills: number, -- brainrot players killed
    incorrect_kills: number, -- NPCs killed
    chances_used: number, -- total chances consumed across all matches
    perfect_games: number, -- matches won without losing any chances
    
    -- Brainrot specific stats
    brainrot_matches: number,
    brainrot_wins: number,
    times_discovered: number, -- times caught by investigadors
    survival_time: number, -- total time survived as brainrot
    
    -- Achievements tracking
    longest_survival: number, -- longest time survived in a single match
    fastest_win: number, -- fastest match won as investigador
    streak_best: number, -- best win streak
    streak_current: number, -- current win streak
}

export type CurrentMatchData = {
    match_id: string?,
    role: PlayerRole,
    match_start_time: number?,
    chances_remaining: number?, -- only for investigadors
    kills_this_match: number,
    deaths_this_match: number,
    is_alive: boolean,
    tasks_completed: number,
    current_zone: string?,
}

export type PlayerSettings = {
    -- UI preferences
    show_debug_info: boolean,
    sound_enabled: boolean,
    music_volume: number, -- 0 to 1
    sfx_volume: number, -- 0 to 1
    
    -- Gameplay preferences
    auto_sprint: boolean,
    camera_sensitivity: number,
    fov: number,
    
    -- Accessibility
    color_blind_mode: boolean,
    reduce_motion: boolean,
    high_contrast: boolean,
}

export type UnlockedContent = {
    -- Cosmetic unlocks
    character_skins: {[string]: boolean},
    emotes: {[string]: boolean},
    victory_poses: {[string]: boolean},
    
    -- Gameplay unlocks
    game_modes: {[string]: boolean},
    maps: {[string]: boolean},
}

export type PlayerData = {
    -- Basic player info
    player_level: number,
    experience_points: number,
    coins: number,
    
    -- Task system
    tasks_completed: {[string]: boolean}, -- task_id -> completed
    
    -- Match statistics
    statistics: MatchStatistics,
    
    -- Player preferences
    settings: PlayerSettings,
    
    -- Unlocked content
    unlocks: UnlockedContent,
    
    -- Premium features
    gamepasses: {},
    
    -- Timestamps
    first_joined: number,
    last_played: number,
    total_play_sessions: number,
}

export type Session<T> = skilift.Session<T>

local player_cache: charm.Atom<{[number]: skilift.Session<PlayerData>}> = charm.atom {}
local player_sessions: {[number]: skilift.Session<PlayerData>} = {}

local is_production: boolean = not RunService:IsStudio()

local data: {
    player_cache: charm.Atom<{PlayerData}>,
    player_sessions: {[number]: skilift.Session<PlayerData>},
    player_store: skilift.Store<PlayerData>,

    player: (player: Player) -> skilift.Session<PlayerData>,
} = {
    player_cache = player_cache,
    player_sessions = player_sessions,
    player_store = skilift.store {
        name = is_production and "player_data" or "dev_player_data",
        migrations = {},        
        default_data = function(): PlayerData
            return {
                -- Basic player info
                player_level = 1,
                experience_points = 0,
                coins = 0,
                
                -- Task system
                tasks_completed = {},
                
                -- Match statistics
                statistics = {
                    -- General match stats
                    matches_played = 0,
                    matches_won = 0,
                    total_playtime = 0,
                    
                    -- Investigador specific stats
                    investigador_matches = 0,
                    investigador_wins = 0,
                    correct_kills = 0,
                    incorrect_kills = 0,
                    chances_used = 0,
                    perfect_games = 0,
                    
                    -- Brainrot specific stats
                    brainrot_matches = 0,
                    brainrot_wins = 0,
                    times_discovered = 0,
                    survival_time = 0,
                    
                    -- Achievements tracking
                    longest_survival = 0,
                    fastest_win = 0,
                    streak_best = 0,
                    streak_current = 0,
                },
                
                -- Player preferences
                settings = {
                    -- UI preferences
                    show_debug_info = false,
                    sound_enabled = true,
                    music_volume = 0.7,
                    sfx_volume = 0.8,
                    
                    -- Gameplay preferences
                    auto_sprint = false,
                    camera_sensitivity = 1.0,
                    fov = 70,
                    
                    -- Accessibility
                    color_blind_mode = false,
                    reduce_motion = false,
                    high_contrast = false,
                },
                
                -- Unlocked content
                unlocks = {
                    -- Cosmetic unlocks
                    character_skins = {
                        ["default"] = true,
                    },
                    emotes = {
                        ["wave"] = true,
                    },
                    victory_poses = {
                        ["default"] = true,
                    },
                },
                
                -- Premium features
                gamepasses = {},
                
                -- Timestamps
                first_joined = os.time(),
                last_played = os.time(),
                total_play_sessions = 0,
            }
        end
    }
}

function data.player(player: Player): skilift.Session<PlayerData>
    local key: number =  player.UserId
    local player_session: skilift.Session<PlayerData> = player_sessions[key]
    if not player_session then 
        repeat 
            task.wait(.1) 
            player_session = player_sessions[key]
        until player_session
    end

    if not player_session:loaded() then 
        while true do 
            task.wait(.1)
            if player_session:loaded() then
                break
            end
        end
    end

    return player_session
end

return data