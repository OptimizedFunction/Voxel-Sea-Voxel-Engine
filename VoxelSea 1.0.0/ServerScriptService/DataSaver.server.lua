local Players = game:GetService("Players")

local dataManager = require(script.Parent["Data Manager"])
local modules = require(game:GetService("ReplicatedStorage")["VoxelSea 2.0"].Modules.ModuleIndex)
local replicator = require(modules.ReplicatorAndUpdateLogger)

local save = dataManager.GetWorldSave()
print(save)
replicator.SetUpdateLog(save)

game:BindToClose(function()
    print(dataManager.SaveWorld(replicator.GetUpdateLog()))
end)
