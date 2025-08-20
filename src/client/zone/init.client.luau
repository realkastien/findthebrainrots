local zone_manager_client = require(script.zone_manager)
local zone_debugger = require(script.zone_debugger)

-- Initialize the zone manager when the client starts
zone_manager_client.init()

-- Initialize the zone debugger
zone_debugger.init()

-- Example usage - connect to zone events
zone_manager_client.on_local_player_entered_zone(function(enter_event)
    -- Here you can add client-side logic for when the local player enters zones
    -- For example, updating UI, playing sounds, visual effects, etc.
end)

zone_manager_client.on_local_player_exited_zone(function(exit_event)
    -- Here you can add client-side logic for when the local player exits zones
    -- For example, updating UI, playing sounds, visual effects, etc.
end)
