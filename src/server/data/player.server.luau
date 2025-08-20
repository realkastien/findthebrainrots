--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local data = require(script.Parent)
local charm = require(ReplicatedStorage.Packages.charm)
local skilift = require(ReplicatedStorage.Packages.skilift)

export type PlayerData = data.PlayerData

local player_data_store: skilift.Store<PlayerData> = data.player_store

type DataCache = charm.Atom<{PlayerData}>

local player_data_cache: DataCache = data.player_cache :: DataCache
local player_sessions: {skilift.Session<PlayerData>} = data.player_sessions

local function load_player_session(player: Player): ()
    local key: number = player.UserId
    local player_session: skilift.Session<PlayerData> = player_data_store:load(tostring(key))

    player_session:userid(key) -- for GDPR metadata

    player_session:updated(function(updated_data: PlayerData): ()
        player_data_cache(function(cache: {PlayerData}): {PlayerData}
            cache[key] = updated_data
            return cache
        end)
    end)

    player_sessions[key] = player_session
end

local function close_player_session(player: Player): ()
    local key: number = player.UserId
    local player_session: skilift.Session<PlayerData> = player_sessions[key]

    if not player_session then
        return
    end

    player_session:stop()
    player_sessions[key] = nil
end

local function close_all_sessions(): ()
    for _, player_session: skilift.Session<PlayerData> in player_sessions do
        player_session:stop()
    end
end

game:BindToClose(close_all_sessions)
Players.PlayerRemoving:Connect(close_player_session)
Players.PlayerAdded:Connect(load_player_session)