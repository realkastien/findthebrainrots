local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charm = require(ReplicatedStorage.Packages.charm)
local skilift = require(ReplicatedStorage.Packages.skilift)
local variables = require(script.variables)
local data = require(script.Parent.data)

export type Variables = {
	current_zone: charm.Atom<string?>,
}

local player = {
	variables = variables,
}

local function add_coin(data: data.PlayerData, amount: number): ()
	data.coins += amount
	return data
end

local function remove_coin(data: data.PlayerData, amount: number): ()
	local new_amount: number = math.max(0, data.coins - amount)
	data.coins = new_amount
	return data
end

local function level_up(data: data.PlayerData, levels: number): ()
	data.player_level += levels
	return data
end

local function give_experience(data: data.PlayerData, amount: number): ()
	data.experience_points += amount
	return data
end

function player.add_coin(player: Player, amount: number): ()
	data.player_sessions[player.UserId]:patch(add_coin, amount or 0)
end

function player.remove_coin(player: Player, amount: number): ()
	data.player_sessions[player.UserId]:patch(remove_coin, amount or 0)
end

function player.level_up(player: Player, levels: number?): ()
	data.player_sessions[player.UserId]:patch(level_up, levels or 1)
end

function player.give_experience(player: Player, amount: number): ()
	data.player_sessions[player.UserId]:patch(give_experience, amount or 0)
end

data.player_store:action(add_coin)
data.player_store:action(remove_coin)
data.player_store:action(level_up)
data.player_store:action(give_experience)

return player