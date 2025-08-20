local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local zone_manager_client = require(script.Parent.zone_manager)

-- Constants
local ZONE_TAG = "Zone"

-- Debugger settings
local DEBUG_ENABLED = false
local INSIDE_COLOR = Color3.fromRGB(0, 255, 0) -- Green when inside
local OUTSIDE_COLOR = Color3.fromRGB(255, 100, 100) -- Red when outside
local TRANSPARENCY = 0.7
local UPDATE_INTERVAL = 0.1 -- Update every 0.1 seconds

-- State
local debug_parts = {}
local debug_connections = {}
local last_update = 0

local zone_debugger = {}

-- Helper function to get zone bounds
local function get_zone_bounds(zone_model)
    local min_pos = Vector3.new(math.huge, math.huge, math.huge)
    local max_pos = Vector3.new(-math.huge, -math.huge, -math.huge)
    
    for _, child in zone_model:GetChildren() do
        if child:IsA("BasePart") then
            local part_min = child.Position - child.Size / 2
            local part_max = child.Position + child.Size / 2
            
            min_pos = Vector3.new(
                math.min(min_pos.X, part_min.X),
                math.min(min_pos.Y, part_min.Y),
                math.min(min_pos.Z, part_min.Z)
            )
            
            max_pos = Vector3.new(
                math.max(max_pos.X, part_max.X),
                math.max(max_pos.Y, part_max.Y),
                math.max(max_pos.Z, part_max.Z)
            )
        end
    end
    
    local center = (min_pos + max_pos) / 2
    local size = max_pos - min_pos
    
    return center, size
end

-- Create debug visualization for a zone
local function create_debug_part(zone_model)
    local zone_id = zone_model:GetAttribute("ZoneId") or zone_model.Name
    
    -- Get zone bounds
    local center, size = get_zone_bounds(zone_model)
    
    -- Create debug part
    local debug_part = Instance.new("Part")
    debug_part.Name = "ZoneDebug_" .. zone_id
    debug_part.CastShadow = false
    debug_part.Size = size
    debug_part.Position = center
    debug_part.Anchored = true
    debug_part.CanCollide = false
    debug_part.Transparency = TRANSPARENCY
    debug_part.Color = OUTSIDE_COLOR
    debug_part.Material = Enum.Material.ForceField
    debug_part.Parent = workspace
    
    -- Create selection box for better visibility
    local selection_box = Instance.new("SelectionBox")
    selection_box.Adornee = debug_part
    selection_box.Color3 = OUTSIDE_COLOR
    selection_box.Transparency = 0.5
    selection_box.LineThickness = 0.2
    selection_box.Parent = debug_part
    
    -- Create zone label
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(40, 0, 10, 0)
    gui.StudsOffset = Vector3.new(0, size.Y / 2 + 2, 0)
    gui.Parent = debug_part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = Color3.new(0, 0, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = zone_id
    label.Parent = gui
    
    -- Store references
    debug_parts[zone_id] = {
        part = debug_part,
        selection_box = selection_box,
        label = label,
        zone_model = zone_model
    }
    
    print("Created debug visualization for zone:", zone_id)
end

-- Remove debug visualization for a zone
local function remove_debug_part(zone_model)
    local zone_id = zone_model:GetAttribute("ZoneId") or zone_model.Name
    local debug_info = debug_parts[zone_id]
    
    if debug_info then
        if debug_info.part then
            debug_info.part:Destroy()
        end
        debug_parts[zone_id] = nil
        print("Removed debug visualization for zone:", zone_id)
    end
end

-- Update zone colors based on player position
local function update_zone_colors()
    if not DEBUG_ENABLED then return end
    
    local zone_stack = zone_manager_client.get_zone_stack()
    local current_zone = zone_manager_client.get_current_zone()
    
    for zone_id, debug_info in debug_parts do
        local is_inside = zone_manager_client.is_in_zone(zone_id)
        local color = is_inside and INSIDE_COLOR or OUTSIDE_COLOR
        
        debug_info.part.Color = color
        debug_info.selection_box.Color3 = color
        
        -- Update label to show status and stack position
        local status_text = zone_id
        if is_inside then
            -- Find position in stack
            local stack_position = nil
            for i, stacked_zone in zone_stack do
                if stacked_zone == zone_id then
                    stack_position = i
                    break
                end
            end
            
            if zone_id == current_zone then
                status_text = zone_id .. " (CURRENT)"
            elseif stack_position then
                status_text = zone_id .. string.format(" (STACK %d/%d)", stack_position, #zone_stack)
            else
                status_text = zone_id .. " (INSIDE)"
            end
        else
            status_text = zone_id .. " (OUTSIDE)"
        end
        
        debug_info.label.Text = status_text
        debug_info.label.TextColor3 = is_inside and INSIDE_COLOR or OUTSIDE_COLOR
    end
end

-- Toggle debug visualization
local function toggle_debug()
    DEBUG_ENABLED = not DEBUG_ENABLED
    
    if DEBUG_ENABLED then
        print("Zone debugger enabled")
        
        -- Create debug parts for existing zones
        for _, zone_model in CollectionService:GetTagged(ZONE_TAG) do
            if zone_model:IsA("Model") then
                create_debug_part(zone_model)
            end
        end
        
        -- Connect update loop
        debug_connections.update = RunService.Heartbeat:Connect(function()
            local current_time = tick()
            if current_time - last_update >= UPDATE_INTERVAL then
                update_zone_colors()
                last_update = current_time
            end
        end)
        
        -- Connect to zone changes
        debug_connections.zone_added = CollectionService:GetInstanceAddedSignal(ZONE_TAG):Connect(function(instance)
            if instance:IsA("Model") and DEBUG_ENABLED then
                create_debug_part(instance)
            end
        end)
        
        debug_connections.zone_removed = CollectionService:GetInstanceRemovedSignal(ZONE_TAG):Connect(function(instance)
            if instance:IsA("Model") then
                remove_debug_part(instance)
            end
        end)
        
    else
        print("Zone debugger disabled")
        
        -- Clean up debug parts
        for zone_id, debug_info in debug_parts do
            if debug_info.part then
                debug_info.part:Destroy()
            end
        end
        debug_parts = {}
        
        -- Disconnect connections
        for _, connection in debug_connections do
            if connection then
                connection:Disconnect()
            end
        end
        debug_connections = {}
    end
end

-- Public API
function zone_debugger.init()
    -- Set up keybind to toggle debug
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.T then
            toggle_debug()
        end
    end)
    
    print("Zone debugger initialized - Press T to toggle visualization")
end

function zone_debugger.enable()
    if not DEBUG_ENABLED then
        toggle_debug()
    end
end

function zone_debugger.disable()
    if DEBUG_ENABLED then
        toggle_debug()
    end
end

function zone_debugger.is_enabled()
    return DEBUG_ENABLED
end

function zone_debugger.set_colors(inside_color, outside_color)
    INSIDE_COLOR = inside_color
    OUTSIDE_COLOR = outside_color
    
    if DEBUG_ENABLED then
        update_zone_colors()
    end
end

function zone_debugger.set_transparency(transparency)
    TRANSPARENCY = transparency
    
    for _, debug_info in debug_parts do
        debug_info.part.Transparency = transparency
    end
end

function zone_debugger.get_debug_info()
    local info = {}
    local zone_stack = zone_manager_client.get_zone_stack()
    local current_zone = zone_manager_client.get_current_zone()
    
    for zone_id, debug_info in debug_parts do
        local is_inside = zone_manager_client.is_in_zone(zone_id)
        local stack_position = nil
        
        if is_inside then
            for i, stacked_zone in zone_stack do
                if stacked_zone == zone_id then
                    stack_position = i
                    break
                end
            end
        end
        
        info[zone_id] = {
            is_inside = is_inside,
            is_current = zone_id == current_zone,
            stack_position = stack_position,
            position = debug_info.part.Position,
            size = debug_info.part.Size
        }
    end
    
    info._zone_stack = zone_stack
    info._current_zone = current_zone
    info._zones_count = #zone_stack
    
    return info
end

function zone_debugger.print_zone_stack()
    local zone_stack = zone_manager_client.get_zone_stack()
    local current_zone = zone_manager_client.get_current_zone()
    
    print("📍 Current Zone Stack:")
    if #zone_stack == 0 then
        print("   (no zones)")
    else
        for i, zone_id in zone_stack do
            local marker = (zone_id == current_zone) and "👑" or "  "
            print(string.format("   %s %d. %s", marker, i, zone_id))
        end
    end
end

-- Connect to zone events for additional feedback
zone_manager_client.on_local_player_entered_zone(function(event)
    if DEBUG_ENABLED then
        local zones_count = zone_manager_client.get_zones_count()
        print(string.format("🟢 ENTERED ZONE: %s (stack depth: %d)", event.zone_id, zones_count))
    end
end)

zone_manager_client.on_local_player_exited_zone(function(event)
    if DEBUG_ENABLED then
        local zones_count = zone_manager_client.get_zones_count()
        local current_zone = zone_manager_client.get_current_zone()
        local current_info = current_zone and string.format(" | current: %s", current_zone) or " | no zones"
        print(string.format("🔴 EXITED ZONE: %s (%.2f seconds | stack depth: %d%s)", 
            event.zone_id, event.time_spent, zones_count, current_info))
    end
end)

return zone_debugger
