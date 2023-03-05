--!nonstrict
local HttpService: HttpService = game:GetService("HttpService")
local modules = require(script.Parent.ModuleIndex)

local config = require(modules.Configuration)
local Voxel = require(modules.VoxelLib)
local assetManager = require(modules.AssetManager)
local utility = require(modules.Utility)

local chunk_size = config.GetChunkSize()
local vert_chunk_size = config.GetVertChunkSize()
local voxel_size = config.GetVoxelSize()

local seed : number = math.random() * 10

local actorFolder = Instance.new("Folder")
actorFolder.Parent = game:GetService("Players").LocalPlayer.PlayerScripts
script.Script.Parent = script.Template
script.Template.Parent = actorFolder

local mat_info = assetManager.Material_Info
local materials = {}

for _, mat in pairs(mat_info) do
    materials[mat.Name] = mat.Code
end

local NUMBER_OF_ACTORS = chunk_size^2

local chunk_manager = {}

function chunk_manager.UpdateChunkWithTerrainData(chunk)
    local init_corner = chunk:GetInitCorner()

	local function GenerateHeightMap()
		local done = 0
		local heightMap = {}
		
		for index = 1, NUMBER_OF_ACTORS do
			
			local actor = actorFolder:FindFirstChild("Actor"..index) or actorFolder.Template:Clone()
			actor.Name = "Actor"..index
			actor:SetAttribute("chunk_size", chunk_size)
			actor:SetAttribute("vert_chunk_size", vert_chunk_size)
			actor:SetAttribute("voxel_size", voxel_size)
			actor:SetAttribute("init_corner", init_corner)
			actor:SetAttribute("seed", seed)
			actor:SetAttribute("index", index)
			
			local conn: RBXScriptConnection
			conn = actor.ComputationCompleted.Event:Connect(function()
				local t = actor:GetAttribute("heightMapVal")
				local i = index%chunk_size
				local k = math.floor(index/chunk_size)
				i = if i == 0 then chunk_size else i
				k = if k == 0 then chunk_size else k

				heightMap[i] = heightMap[i] or {}
				heightMap[i][k] = t
				done += 1
				conn:Disconnect()
			end)
			
			actor.Parent = actorFolder
			actor.Script.Enabled = true
		end
		repeat task.wait() 
		until done >= NUMBER_OF_ACTORS
		
		return heightMap
		
	end
	
    local function Generate(height_map)
        for i = 1, chunk_size do
            for k = 1, chunk_size do
                for j = 1, height_map[i][k]-1 do
                    local index = Voxel.GetIndex(i,j,k)
                    chunk.Voxels[index] = Voxel.new(2)
                end
                local index = Voxel.GetIndex(i, height_map[i][k], k)
                chunk.Voxels[index] = Voxel.new(1)
            end
        end
    end

    local height_map = GenerateHeightMap()
    Generate(height_map)

    height_map = nil

end


return chunk_manager
