local data = require(script.Parent.data)
local task_system = {}

local function compute_task_completed(data: data.PlayerData): ()
    data.tasks_completed += 1
    return data
end

data.player_store:action(compute_task_completed)

function task_system.complete(player: Player, task_id: number): ()
    data.player_sessions[player.UserId]:patch(compute_task_completed)

    -- Do whatever more here
end

return task_system 