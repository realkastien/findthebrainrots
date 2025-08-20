local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zone_types = require(ReplicatedStorage.Shared.zone_types)

-- Constants for zone system
local CONSTANTS = {
    ZONE_TAG = "Zone",
    BLOCK_ZONE_TAG = "BlockZone",
    
    -- Zone attributes
    ZONE_ID_ATTRIBUTE = "ZoneId",
    ZONE_TYPE_ATTRIBUTE = "ZoneType",
    ZONE_LEVEL_ATTRIBUTE = "ZoneLevel",
    
    -- Zone types
    ZONE_TYPES = {
        MINING = "Mining",
        LOBBY = "Lobby",
        SHOP = "Shop",
        TELEPORT = "Teleport",
    },
}

local zone_utils = {}

-- Utility functions for zone operations
function zone_utils.generate_zone_id(zone_name, zone_level)
    if zone_level then
        return string.format("%s_Level%d", zone_name, zone_level)
    end
    return zone_name
end

function zone_utils.parse_zone_id(zone_id)
    local parts = string.split(zone_id, "_Level")
    if #parts == 2 then
        local level = tonumber(parts[2])
        return parts[1], level
    end
    return zone_id, nil
end

function zone_utils.is_mining_zone(zone_id)
    local zone_name, _ = zone_utils.parse_zone_id(zone_id)
    return zone_name == CONSTANTS.ZONE_TYPES.MINING
end

function zone_utils.get_zone_level(zone_id)
    local _, level = zone_utils.parse_zone_id(zone_id)
    return level
end

function zone_utils.setup_zone_model(zone_model, zone_config)
    -- Set zone attributes
    if zone_config.zone_id then
        zone_model:SetAttribute(CONSTANTS.ZONE_ID_ATTRIBUTE, zone_config.zone_id)
    end
    
    if zone_config.zone_type then
        zone_model:SetAttribute(CONSTANTS.ZONE_TYPE_ATTRIBUTE, zone_config.zone_type)
    end
    
    if zone_config.zone_level then
        zone_model:SetAttribute(CONSTANTS.ZONE_LEVEL_ATTRIBUTE, zone_config.zone_level)
    end
end

function zone_utils.validate_zone_model(zone_model)
    -- Check if model has proper structure for a zone
    if not zone_model:IsA("Model") then
        return false
    end
    
    -- Check if it has at least one part for zone detection
    local has_parts = false
    for _, child in zone_model:GetChildren() do
        if child:IsA("BasePart") then
            has_parts = true
            break
        end
    end
    
    return has_parts
end

function zone_utils.get_zone_config_from_model(zone_model)
    return {
        zone_id = zone_model:GetAttribute(CONSTANTS.ZONE_ID_ATTRIBUTE),
        zone_type = zone_model:GetAttribute(CONSTANTS.ZONE_TYPE_ATTRIBUTE),
        zone_level = zone_model:GetAttribute(CONSTANTS.ZONE_LEVEL_ATTRIBUTE),
    }
end

-- Time utilities
function zone_utils.format_time_spent(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remaining_seconds = seconds % 60
        return string.format("%dm %.0fs", minutes, remaining_seconds)
    else
        local hours = math.floor(seconds / 3600)
        local remaining_minutes = math.floor((seconds % 3600) / 60)
        return string.format("%dh %dm", hours, remaining_minutes)
    end
end

-- Export constants and types
zone_utils.CONSTANTS = CONSTANTS
zone_utils.Types = zone_types

return zone_utils
