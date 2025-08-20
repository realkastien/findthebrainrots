local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zone = require(ReplicatedStorage.Packages.zoneplus)
local signal = require(ReplicatedStorage.Packages.signal)

-- Constants
local ZONE_TAG = "Zone"
local LocalPlayer = Players.LocalPlayer

-- Module state
local zone_instances = {}
local player_zone_cache = {
    zone_stack = {},
    zone_enter_times = {}
}

-- Signals for zone events
local zone_entered_signal = signal.new()
local zone_exited_signal = signal.new()

local zone_manager_client = {}

-- Private functions
local function get_zone_id_from_model(zone_model: Model): string
    return zone_model:GetAttribute("ZoneId")::string or zone_model.Name
end

local function create_zone_info(zone_model)
    local zone_id = get_zone_id_from_model(zone_model)
    local zone_instance = zone.new(zone_model:WaitForChild("Hitbox"))
    
    -- Configure zone detection for optimal performance on client
    zone_instance:setAccuracy(zone.enum.Accuracy.Low)
    zone_instance:setDetection(zone.enum.Detection.Centre)
    
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
    
    -- Local player entered zone
    zone_instance.localPlayerEntered:Connect(function()
        local current_time = tick()
        local previous_zone_id = player_zone_cache.zone_stack[#player_zone_cache.zone_stack] -- Current top of stack
        
        -- Add zone to stack
        table.insert(player_zone_cache.zone_stack, zone_id)
        player_zone_cache.zone_enter_times[zone_id] = current_time
        
        -- Create enter event
        local enter_event = {
            player_id = LocalPlayer.UserId,
            zone_id = zone_id,
            enter_time = current_time,
            previous_zone = previous_zone_id,
        }
        
        zone_entered_signal:Fire(enter_event)
    end)
    
    -- Local player exited zone
    zone_instance.localPlayerExited:Connect(function()
        local current_time = tick()
        
        -- Find and remove zone from stack
        for i = #player_zone_cache.zone_stack, 1, -1 do
            if player_zone_cache.zone_stack[i] == zone_id then
                table.remove(player_zone_cache.zone_stack, i)
                break
            end
        end
        
        local enter_time = player_zone_cache.zone_enter_times[zone_id] or current_time
        local time_spent = current_time - enter_time
        player_zone_cache.zone_enter_times[zone_id] = nil
        
        -- Create exit event
        local exit_event = {
            player_id = LocalPlayer.UserId,
            zone_id = zone_id,
            exit_time = current_time,
            time_spent = time_spent,
        }
        
        zone_exited_signal:Fire(exit_event)
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
end

-- Public API
function zone_manager_client.init()
    -- Wait for LocalPlayer to be available
    if not LocalPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end
    
    -- Connect to CollectionService events
    CollectionService:GetInstanceAddedSignal(ZONE_TAG):Connect(mount_zone)
    CollectionService:GetInstanceRemovedSignal(ZONE_TAG):Connect(unmount_zone)
    
    -- Mount existing zones
    for _, zone_model in CollectionService:GetTagged(ZONE_TAG) do
        mount_zone(zone_model)
    end
    print("[ZONE MANAGER] Initialized on client")
end

function zone_manager_client.get_zone_info(zone_id)
    return zone_instances[zone_id]
end

function zone_manager_client.get_all_zones()
    return zone_instances
end

function zone_manager_client.get_current_zone(): string?
    if #player_zone_cache.zone_stack == 0 then
        return nil
    end
    return player_zone_cache.zone_stack[#player_zone_cache.zone_stack] -- Return top of stack
end

function zone_manager_client.get_zone_data()
    return player_zone_cache
end

function zone_manager_client.get_zone_stack()
    return player_zone_cache.zone_stack
end

function zone_manager_client.get_zones_count()
    return #player_zone_cache.zone_stack
end

function zone_manager_client.is_in_zone(zone_id)
    local zone_info = zone_instances[zone_id]
    if not zone_info then return false end
    
    return zone_info.zone_instance:findLocalPlayer()
end

-- Event connections
function zone_manager_client.on_local_player_entered_zone(callback)
    return zone_entered_signal:Connect(callback)
end

function zone_manager_client.on_local_player_exited_zone(callback)
    return zone_exited_signal:Connect(callback)
end

-- Force update current zone (useful for debugging)
function zone_manager_client.force_update_current_zone()
    local current_zones = {}
    local current_time = tick()
    
    -- Find all zones player is currently in
    for zone_id, zone_info in zone_instances do
        local is_in_zone = zone_info.zone_instance:findLocalPlayer()
        if is_in_zone then
            table.insert(current_zones, zone_id)
        end
    end
    
    -- Update the stack to match current reality
    for _, zone_id in current_zones do
        local found = false
        for _, stacked_zone in player_zone_cache.zone_stack do
            if stacked_zone == zone_id then
                found = true
                break
            end
        end
        
        if not found then
            -- Zone not in stack, add it
            local previous_zone_id = player_zone_cache.zone_stack[#player_zone_cache.zone_stack]
            table.insert(player_zone_cache.zone_stack, zone_id)
            player_zone_cache.zone_enter_times[zone_id] = current_time
            
            local enter_event = {
                player_id = LocalPlayer.UserId,
                zone_id = zone_id,
                enter_time = current_time,
                previous_zone = previous_zone_id,
            }
            
            zone_entered_signal:Fire(enter_event)
        end
    end
    
    -- Remove zones from stack that player is no longer in
    for i = #player_zone_cache.zone_stack, 1, -1 do
        local zone_id = player_zone_cache.zone_stack[i]
        local still_in_zone = false
        
        for _, current_zone in current_zones do
            if current_zone == zone_id then
                still_in_zone = true
                break
            end
        end
        
        if not still_in_zone then
            table.remove(player_zone_cache.zone_stack, i)
            local enter_time = player_zone_cache.zone_enter_times[zone_id] or current_time
            local time_spent = current_time - enter_time
            player_zone_cache.zone_enter_times[zone_id] = nil
            
            local exit_event = {
                player_id = LocalPlayer.UserId,
                zone_id = zone_id,
                exit_time = current_time,
                time_spent = time_spent,
            }
            
            zone_exited_signal:Fire(exit_event)
        end
    end
end

return zone_manager_client
