local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zone = require(ReplicatedStorage.Packages.zoneplus)
local Signal = require(ReplicatedStorage.Packages.signal)

-- Constants
local ZONE_TAG = "Zone"

-- Module state
local zone_instances = {}
local player_zone_cache = {} -- Now stores: { zone_stack = {}, zone_enter_times = {} }

-- Signals for zone events
local zone_entered_signal = Signal.new()
local zone_exited_signal = Signal.new()

local zone_manager = {}

-- Private functions
local function get_zone_id_from_model(zone_model: Model): string
    return zone_model:GetAttribute("ZoneId")::string or zone_model.Name
end

local function create_zone_info(zone_model)
    local zone_id = get_zone_id_from_model(zone_model)
    local zone_instance = Zone.new(zone_model.Hitbox)
    
    -- Configure zone detection for optimal performance
    zone_instance:setAccuracy(Zone.enum.Accuracy.High)
    zone_instance:setDetection(Zone.enum.Detection.Centre)
    
    local zone_info = {
        id = zone_id,
        name = zone_model.Name,
        model = zone_model,
        zone_instance = zone_instance,
    }
    
    return zone_info
end

local function setup_zone_events(zone_info)
    local zone_instance = zone_info.zone_instance
    local zone_id = zone_info.id
    
    -- Player entered zone
    zone_instance.playerEntered:Connect(function(player)
        if not player or not player.Parent then return end
        
        local player_id = player.UserId
        local current_time = tick()
        
        -- Initialize player cache if needed
        if not player_zone_cache[player_id] then
            player_zone_cache[player_id] = {
                zone_stack = {},
                zone_enter_times = {}
            }
        end
        
        local cache = player_zone_cache[player_id]
        local previous_zone_id = cache.zone_stack[#cache.zone_stack] -- Current top of stack
        
        -- Add zone to stack
        table.insert(cache.zone_stack, zone_id)
        cache.zone_enter_times[zone_id] = current_time
        
        -- Create enter event
        local enter_event = {
            player_id = player_id,
            zone_id = zone_id,
            enter_time = current_time,
            previous_zone = previous_zone_id,
        }
        
        zone_entered_signal:Fire(enter_event)
        print(string.format("Player %s entered zone %s (stack depth: %d)", player.Name, zone_id, #cache.zone_stack))
    end)
    
    -- Player exited zone
    zone_instance.playerExited:Connect(function(player)
        if not player or not player.Parent then return end
        
        local player_id = player.UserId
        local current_time = tick()
        
        -- Get cached data
        local cache = player_zone_cache[player_id]
        if not cache then return end
        
        -- Find and remove zone from stack
        for i = #cache.zone_stack, 1, -1 do
            if cache.zone_stack[i] == zone_id then
                table.remove(cache.zone_stack, i)
                break
            end
        end
        
        local enter_time = cache.zone_enter_times[zone_id] or current_time
        local time_spent = current_time - enter_time
        cache.zone_enter_times[zone_id] = nil
        
        -- Create exit event
        local exit_event = {
            player_id = player_id,
            zone_id = zone_id,
            exit_time = current_time,
            time_spent = time_spent,
        }
        
        zone_exited_signal:Fire(exit_event)
        print(string.format("Player %s exited zone %s after %.2f seconds (stack depth: %d)", player.Name, zone_id, time_spent, #cache.zone_stack))
    end)
end

local function mount_zone(zone_model)
    if not zone_model:IsA("Model") then
        warn(string.format("Zone tag applied to non-Model instance: %s", zone_model:GetFullName()))
        return
    end
    
    local zone_id: string = get_zone_id_from_model(zone_model)
    
    -- Check if zone already exists
    if zone_instances[zone_id] then
        warn(string.format("Zone with ID %s already exists", zone_id))
        return
    end
    
    local zone_info = create_zone_info(zone_model)
    setup_zone_events(zone_info)
    
    zone_instances[zone_id] = zone_info
    
    print(string.format("Mounted zone: %s", zone_id))
end

local function unmount_zone(zone_model)
    local zone_id = get_zone_id_from_model(zone_model)
    local zone_info = zone_instances[zone_id]
    
    if not zone_info then return end
    
    -- Cleanup zone instance
    if zone_info.zone_instance and zone_info.zone_instance.janitor then
        zone_info.zone_instance.janitor:destroy()
    end
    
    zone_instances[zone_id] = nil
    
    print(string.format("Unmounted zone: %s", zone_id))
end

local function cleanup_player_cache(player)
    local player_id = player.UserId
    player_zone_cache[player_id] = nil
end

-- Public API
function zone_manager.init()
    -- Connect to CollectionService events
    CollectionService:GetInstanceAddedSignal(ZONE_TAG):Connect(mount_zone)
    CollectionService:GetInstanceRemovedSignal(ZONE_TAG):Connect(unmount_zone)
    
    -- Mount existing zones
    for _, zone_model in CollectionService:GetTagged(ZONE_TAG) do
        mount_zone(zone_model)
    end
    
    -- Cleanup player cache when players leave
    Players.PlayerRemoving:Connect(cleanup_player_cache)
    
    print("Zone manager initialized on server")
end

function zone_manager.get_zone_info(zone_id)
    return zone_instances[zone_id]
end

function zone_manager.get_all_zones()
    return zone_instances
end

function zone_manager.get_player_current_zone(player_id)
    local cache = player_zone_cache[player_id]
    if not cache or #cache.zone_stack == 0 then
        return nil
    end
    return cache.zone_stack[#cache.zone_stack] -- Return top of stack
end

function zone_manager.get_player_zone_data(player_id)
    return player_zone_cache[player_id]
end

function zone_manager.get_player_zone_stack(player_id)
    local cache = player_zone_cache[player_id]
    if not cache then return {} end
    return cache.zone_stack
end

function zone_manager.get_player_zones_count(player_id)
    local cache = player_zone_cache[player_id]
    if not cache then return 0 end
    return #cache.zone_stack
end

function zone_manager.get_players_in_zone(zone_id)
    local zone_info = zone_instances[zone_id]
    if not zone_info then return {} end
    
    return zone_info.zone_instance:getPlayers()
end

-- Event connections
function zone_manager.on_player_entered_zone(callback)
    return zone_entered_signal:Connect(callback)
end

function zone_manager.on_player_exited_zone(callback)
    return zone_exited_signal:Connect(callback)
end

-- Force update zone for player (useful for debugging)
function zone_manager.force_update_player_zone(player)
    local player_id = player.UserId
    
    -- Initialize cache if needed
    if not player_zone_cache[player_id] then
        player_zone_cache[player_id] = {
            zone_stack = {},
            zone_enter_times = {}
        }
    end
    
    local cache = player_zone_cache[player_id]
    local current_zones = {}
    local current_time = tick()
    
    -- Find all zones player is currently in
    for zone_id, zone_info in zone_instances do
        local is_in_zone = zone_info.zone_instance:findPlayer(player)
        if is_in_zone then
            table.insert(current_zones, zone_id)
        end
    end
    
    -- Update the stack to match current reality
    for _, zone_id in current_zones do
        local found = false
        for _, stacked_zone in cache.zone_stack do
            if stacked_zone == zone_id then
                found = true
                break
            end
        end
        
        if not found then
            -- Zone not in stack, add it
            local previous_zone_id = cache.zone_stack[#cache.zone_stack]
            table.insert(cache.zone_stack, zone_id)
            cache.zone_enter_times[zone_id] = current_time
            
            local enter_event = {
                player_id = player_id,
                zone_id = zone_id,
                enter_time = current_time,
                previous_zone = previous_zone_id,
            }
            
            zone_entered_signal:Fire(enter_event)
        end
    end
    
    -- Remove zones from stack that player is no longer in
    for i = #cache.zone_stack, 1, -1 do
        local zone_id = cache.zone_stack[i]
        local still_in_zone = false
        
        for _, current_zone in current_zones do
            if current_zone == zone_id then
                still_in_zone = true
                break
            end
        end
        
        if not still_in_zone then
            table.remove(cache.zone_stack, i)
            local enter_time = cache.zone_enter_times[zone_id] or current_time
            local time_spent = current_time - enter_time
            cache.zone_enter_times[zone_id] = nil
            
            local exit_event = {
                player_id = player_id,
                zone_id = zone_id,
                exit_time = current_time,
                time_spent = time_spent,
            }
            
            zone_exited_signal:Fire(exit_event)
        end
    end
end

return zone_manager
