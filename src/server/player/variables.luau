local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local charm = require(ReplicatedStorage.Packages.charm)
local variables = {}

local atom = charm.atom

type cache = {[any]:any}

local cache: {cache} = {}

local function clean_cache(player: Player): ()
	if not player then
		return
	end

	cache[player.UserId] = nil
end

local function create_cache(player_id: number): cache
	if not cache[player_id] then
		cache[player_id] = {
			current_zone = atom(),
		}
	end

	return cache[player_id]
end

Players.PlayerRemoving:Connect(clean_cache)

function variables.get(player_id: number): cache
	return cache[player_id] or create_cache(player_id)
end

return variables