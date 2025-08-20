local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local character_scripts = ServerStorage.Character

local scripts = {}

for _, script in character_scripts:GetChildren() do 
    if not script:IsA("ModuleScript") then
        continue
    end

    if not script:IsA("Script") then
        continue 
    end

    script.Enabled = false 
    table.insert(scripts, script)
end

Players.PlayerAdded:Connect(function(player: Player): ()
    player.CharacterAdded:Connect(function(character: Model): ()
        for _, script in scripts do
             script = script:Clone()
             script.Parent = character
        end
    end)
end)
