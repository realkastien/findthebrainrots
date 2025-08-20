--!strict
-- State Machine Module for Find The Brainrots Match System
-- Handles all match state transitions and validation

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local common_types = require(ReplicatedFirst.Config.common_types)
local Signal = require(ReplicatedStorage.Packages.signal)

type MatchState = common_types.MatchState

-- State transition events data
export type StateTransition = {
    from_state: MatchState,
    to_state: MatchState,
    timestamp: number,
    reason: string?,
    player_count: number?,
}

-- State machine configuration
export type StateMachineConfig = {
    lobby_timeout: number,
    countdown_duration: number,
    match_duration: number,
    min_players: number,
    max_players: number,
}

-- State machine implementation
export type StateMachine = {
    current_state: MatchState,
    previous_state: MatchState?,
    state_enter_time: number,
    config: StateMachineConfig,
    state_history: {StateTransition},
    player_count: number,
    
    -- Events
    state_changed: any, -- Signal connection
    state_enter_callbacks: {[MatchState]: {() -> ()}},
    state_exit_callbacks: {[MatchState]: {() -> ()}},
    
    -- Internal state
    is_destroyed: boolean,
    auto_transition_thread: thread?,
    
    -- Methods
    Destroy: (self: StateMachine) -> (),
    GetState: (self: StateMachine) -> MatchState,
    CanTransition: (self: StateMachine, to_state: MatchState) -> boolean,
    TransitionTo: (self: StateMachine, to_state: MatchState, reason: string?) -> boolean,
    GetStateHistory: (self: StateMachine) -> {StateTransition},
    GetTimeInState: (self: StateMachine) -> number,
    IsValidTransition: (self: StateMachine, from_state: MatchState, to_state: MatchState) -> boolean,
    GetValidTransitions: (self: StateMachine) -> {MatchState},
    OnStateChanged: (self: StateMachine, callback: (MatchState, MatchState, string?) -> ()) -> () -> (),
    OnEnterState: (self: StateMachine, state: MatchState, callback: () -> ()) -> () -> (),
    OnExitState: (self: StateMachine, state: MatchState, callback: () -> ()) -> () -> (),
    Update: (self: StateMachine, delta_time: number) -> (),
    SetPlayerCount: (self: StateMachine, count: number) -> (),
    
    -- Private methods
    _validateStateConditions: (self: StateMachine, to_state: MatchState) -> boolean,
    _scheduleAutoTransitions: (self: StateMachine, state: MatchState) -> (),
    _checkAutoTransitions: (self: StateMachine) -> (),
}

-- Valid state transitions map
local VALID_TRANSITIONS: {[MatchState]: {MatchState}} = {
    ["lobby"] = {"countdown" :: MatchState, "ended" :: MatchState},
    ["countdown"] = {"playing" :: MatchState, "lobby" :: MatchState, "ended" :: MatchState},
    ["playing"] = {"ended" :: MatchState},
    ["ended"] = {"lobby" :: MatchState},
}

-- Default configuration
local DEFAULT_CONFIG: StateMachineConfig = {
    lobby_timeout = 300, -- 5 minutes
    countdown_duration = 10, -- 10 seconds
    match_duration = 300, -- 5 minutes
    min_players = 4,
    max_players = 8,
}

-- Constructor
local function new(config: StateMachineConfig?): StateMachine
    local final_config = table.clone(DEFAULT_CONFIG)
    
    -- Merge with provided config
    if config then
        if config.lobby_timeout then final_config.lobby_timeout = config.lobby_timeout end
        if config.countdown_duration then final_config.countdown_duration = config.countdown_duration end
        if config.match_duration then final_config.match_duration = config.match_duration end
        if config.min_players then final_config.min_players = config.min_players end
        if config.max_players then final_config.max_players = config.max_players end
    end
    
    local self: StateMachine = {
        current_state = "lobby",
        previous_state = nil,
        state_enter_time = os.clock(),
        config = final_config,
        state_history = {},
        player_count = 0,
        
        -- Events
        state_changed = Signal.new(),
        state_enter_callbacks = {
            ["lobby"] = {},
            ["countdown"] = {},
            ["playing"] = {},
            ["ended"] = {},
        },
        state_exit_callbacks = {
            ["lobby"] = {},
            ["countdown"] = {},
            ["playing"] = {},
            ["ended"] = {},
        },
          -- Internal state
        is_destroyed = false,
        auto_transition_thread = nil,
    } :: any
    
    -- Add methods to self
    function self:GetState(): MatchState
        return self.current_state
    end
    
    function self:CanTransition(to_state: MatchState): boolean
        if self.is_destroyed then
            return false
        end
        return self:IsValidTransition(self.current_state, to_state)
    end
    
    function self:IsValidTransition(from_state: MatchState, to_state: MatchState): boolean
        local valid_transitions = VALID_TRANSITIONS[from_state]
        if not valid_transitions then
            return false
        end
        
        for _, valid_state in valid_transitions do
            if valid_state == to_state then
                return true
            end
        end
        
        return false
    end
    
    function self:GetValidTransitions(): {MatchState}
        if self.is_destroyed then
            return {}
        end
        return VALID_TRANSITIONS[self.current_state] or {}
    end
    
    function self:_validateStateConditions(to_state: MatchState): boolean
        if to_state == "countdown" then
            -- Need minimum players to start countdown
            if self.player_count < self.config.min_players then
                return false
            end
        elseif to_state == "playing" then
            -- Need minimum players to actually start playing
            if self.player_count < self.config.min_players then
                return false
            end
        end
        
        return true
    end
    
    function self:TransitionTo(to_state: MatchState, reason: string?): boolean
        if self.is_destroyed then
            return false
        end
        
        if not self:CanTransition(to_state) then
            warn(`Cannot transition from {self.current_state} to {to_state}`)
            return false
        end
        
        -- Additional validation based on state and conditions
        if not self:_validateStateConditions(to_state) then
            return false
        end
        
        local old_state = self.current_state
        
        -- Execute exit callbacks for current state
        local exit_callbacks = self.state_exit_callbacks[old_state]
        if exit_callbacks then
            for _, callback in exit_callbacks do
                local success = pcall(callback)
                if not success then
                    warn(`Error in exit callback for state {old_state}`)
                end
            end
        end
          -- Update state
        self.previous_state = old_state
        self.current_state = to_state
        self.state_enter_time = os.clock()
        
        -- Cancel any existing auto-transition thread
        if self.auto_transition_thread then
            task.cancel(self.auto_transition_thread)
            self.auto_transition_thread = nil
        end
        
        -- Record transition
        table.insert(self.state_history, {
            from_state = old_state,
            to_state = to_state,
            timestamp = self.state_enter_time,
            reason = reason or "Manual transition",
            player_count = self.player_count,
        })
        
        -- Execute enter callbacks for new state
        local enter_callbacks = self.state_enter_callbacks[to_state]
        if enter_callbacks then
            for _, callback in enter_callbacks do
                local success = pcall(callback)
                if not success then
                    warn(`Error in enter callback for state {to_state}`)
                end
            end
        end
        
        -- Fire state changed event
        self.state_changed:Fire(to_state, old_state)
        
        -- Schedule auto-transitions if needed
        self:_scheduleAutoTransitions(to_state)
        
        return true
    end
      function self:_scheduleAutoTransitions(state: MatchState): ()
        -- Cancel any existing auto-transition thread
        if self.auto_transition_thread then
            task.cancel(self.auto_transition_thread)
            self.auto_transition_thread = nil
        end
        
        -- Schedule new auto-transition based on state
        if state == "countdown" then
            -- Auto-transition to playing after countdown
            self.auto_transition_thread = task.delay(self.config.countdown_duration, function()
                if not self.is_destroyed and self.current_state == "countdown" then
                    self:TransitionTo("playing", "Countdown completed")
                end
            end)
        elseif state == "playing" then
            -- Auto-transition to ended after match duration
            self.auto_transition_thread = task.delay(self.config.match_duration, function()
                if not self.is_destroyed and self.current_state == "playing" then
                    self:TransitionTo("ended", "Match time expired")
                end
            end)
        elseif state == "lobby" then
            -- Auto-transition to countdown if lobby timeout
            self.auto_transition_thread = task.delay(self.config.lobby_timeout, function()
                if not self.is_destroyed and self.current_state == "lobby" and self.player_count >= self.config.min_players then
                    self:TransitionTo("countdown", "Lobby timeout")
                end
            end)
        end
    end
    
    function self:GetStateHistory(): {StateTransition}
        local history = {}
        for _, transition in self.state_history do
            table.insert(history, transition)
        end
        return history
    end
    
    function self:GetTimeInState(): number
        return os.clock() - self.state_enter_time
    end
    
    function self:OnStateChanged(callback: (MatchState, MatchState, string?) -> ()): () -> ()
        local connection = self.state_changed:Connect(function(new_state: MatchState, old_state: MatchState)
            callback(new_state, old_state, nil)
        end)
        return function()
            connection:Disconnect()
        end
    end
    
    function self:OnEnterState(state: MatchState, callback: () -> ()): () -> ()
        local callbacks = self.state_enter_callbacks[state]
        if not callbacks then
            callbacks = {}
            self.state_enter_callbacks[state] = callbacks
        end
        
        table.insert(callbacks, callback)
        
        -- Return disconnect function
        return function()
            local index = table.find(callbacks, callback)
            if index then
                table.remove(callbacks, index)
            end
        end
    end
    
    function self:OnExitState(state: MatchState, callback: () -> ()): () -> ()
        local callbacks = self.state_exit_callbacks[state]
        if not callbacks then
            callbacks = {}
            self.state_exit_callbacks[state] = callbacks
        end
        
        table.insert(callbacks, callback)
        
        -- Return disconnect function
        return function()
            local index = table.find(callbacks, callback)
            if index then
                table.remove(callbacks, index)
            end
        end
    end
    
    function self:_checkAutoTransitions(): ()
        local current_state = self.current_state
        
        -- Auto-transition from lobby if enough players
        if current_state == "lobby" and self.player_count >= self.config.min_players then
            if self:GetTimeInState() >= 5 then -- Grace period of 5 seconds
                self:TransitionTo("countdown", "Enough players joined")
            end
        end
        
        -- Auto-transition from countdown if not enough players
        if current_state == "countdown" and self.player_count < self.config.min_players then
            self:TransitionTo("lobby", "Not enough players")
        end
        
        -- Auto-transition from playing if no players left
        if current_state == "playing" and self.player_count == 0 then
            self:TransitionTo("ended", "No players remaining")
        end
    end
    
    function self:Update(delta_time: number): ()
        if self.is_destroyed then
            return
        end
        
        -- Check for automatic transitions based on conditions
        self:_checkAutoTransitions()
    end
    
    function self:SetPlayerCount(count: number): ()
        if self.is_destroyed then
            return
        end
        
        self.player_count = count
        
        -- Trigger auto-transition checks
        self:_checkAutoTransitions()
    end    
    
    function self:Destroy(): ()
        if self.is_destroyed then
            return
        end
        
        self.is_destroyed = true
        
        -- Cancel any auto-transition thread
        if self.auto_transition_thread then
            task.cancel(self.auto_transition_thread)
            self.auto_transition_thread = nil
        end
        
        -- Clear all callbacks
        for state, callbacks in self.state_enter_callbacks do
            table.clear(callbacks)
        end
        for state, callbacks in self.state_exit_callbacks do
            table.clear(callbacks)
        end
        
        -- Clear state history
        table.clear(self.state_history)
        
        -- Clear signal reference
        self.state_changed = nil
    end
    
    -- Log initial state
    table.insert(self.state_history, {
        from_state = "lobby",
        to_state = "lobby",
        timestamp = os.clock(),
        reason = "Initial state",
        player_count = 0,
    })
    
    return self
end

-- Export the state machine
return {
    new = new,
    DEFAULT_CONFIG = DEFAULT_CONFIG,
    VALID_TRANSITIONS = VALID_TRANSITIONS,
}