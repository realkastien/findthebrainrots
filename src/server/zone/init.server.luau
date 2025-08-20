local player = require(script.Parent.player)
local zone_manager = require(script.zone_manager)

-- Initialize the zone manager when the server starts
zone_manager.init()

-- Updates player data when they enter a zone
zone_manager.on_player_entered_zone(function(enter_event)
    local player_variables: player.Variables = player.variables.get(enter_event.player_id)
	player_variables.current_zone(enter_event.zone_id)
end)

-- Updates player data when they exit a zone
zone_manager.on_player_exited_zone(function(exit_event)
    local player_variables: player.Variables = player.variables.get(exit_event.player_id)
	player_variables.current_zone(nil)
end)
