local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local common_types = require(ReplicatedFirst.Config.common_types)
local Signal = require(ReplicatedStorage.Packages.signal)

type MatchState = common_types.MatchState
type Signal<T> = Signal.Signal<T>

local match: {
    state: MatchState,
    start_time: number?, -- Timestamp when the match started
    end_time: number?, -- Timestamp when the match ended
    players: {Player}, -- Player data indexed by UserId
    roles: {common_types.PlayerRole}, -- Player roles indexed by UserId

    events: {
        state_changed: Signal<MatchState>,
    },
} = {
    state = "lobby",
    start_time = nil,
    end_time = nil,
    players = {},
    roles = {},

    events = {
        state_changed = Signal.new(),
    }
}

function match.set_state(new_state: MatchState): ()
    match.state = new_state
end

function match.player_joined(player: Player): ()
    
end

function match.player_left(player: Player): ()
    
end

return match