--!nocheck
local replicator = {}

local modules = require(script.Parent.ModuleIndex)
local Voxel = require(modules.VoxelLib)
local utility = require(modules.Utility)
local configuration = require(modules.Configuration)

replicator.VoxariaObjectsFolder = workspace:FindFirstChild('VoxariaObjects')


replicator.RenderedChunkList = {}
replicator.LoadedChunkList = {}


local isClient = game:GetService("RunService"):IsClient()
local isServer = game:GetService("RunService"):IsServer()


--client-only
if isClient then
	-- always initialise client in every local script relating to Voxaria.
    function replicator.InitialiseClient()
        if replicator.VoxariaObjectsFolder == nil then
            local folder = Instance.new('Folder')
            folder.Name = 'VoxariaObjects'
            folder.Parent = workspace
			replicator.VoxariaObjectsFolder = folder
		end
		
		--connections
		local conn1 : RBXScriptConnection
		
		local remotes = script.Parent.Parent.Remotes
		local build_remote = remotes.RemoteEvents.building
		if not conn1 then
			conn1 = build_remote.OnClientEvent:Connect(replicator.ProcessUpdate)
		end
	end


	function replicator.RequestReplication(data_table)
 		local remotes = script.Parent.Parent.Remotes
		local building = remotes.RemoteEvents.building

		building:FireServer(data_table)
	end

	function replicator.ProcessUpdate(plrRequestingUpdate, updates)
		if plrRequestingUpdate and game:GetService('Players').LocalPlayer == plrRequestingUpdate then return end
		local to_be_updated_chunks = {}
		
		for _, update in pairs(updates) do
			
			local chunk = update[1]
			local index = update[2]
			local new_ID = update[4]
						
			local local_chunk = require(modules.Chunk).GetChunkFromPos(chunk.Position)
			
			if local_chunk then
				local_chunk.Voxels[index] = new_ID
				if not table.find(to_be_updated_chunks, local_chunk) then 
					table.insert(to_be_updated_chunks, local_chunk)
				end
			end
			
		end
		
		for _,chunk in pairs(to_be_updated_chunks) do
			chunk:Update()
		end
	end

	
	function replicator.GetUpdatesForChunks(chunkPositions : {Vector3}) 
		local remote = script.Parent.Parent.Remotes.RemoteFunctions:WaitForChild('update')
		return remote:InvokeServer(chunkPositions)
	end

end

--server-only 
if isServer then
	
	local update_log = {}
	
	local conn1 : RBXScriptConnection 
	
	function replicator.InitialiseServer()
		
		--connections/remote function callback assignments
		
		--update log loading
		script.Parent.Parent.Remotes.RemoteFunctions:WaitForChild('update').OnServerInvoke = function(_, chunkPositions : {})
			local updates_to_return = {}
			for _, pos in pairs(chunkPositions) do

				if update_log[pos] then
					table.insert(updates_to_return, {pos, update_log[pos]})
				else
					continue
				end

			end
			return updates_to_return
		end
		
		--building replication connection
		local remotes = script.Parent.Parent.Remotes
		local build_remote = remotes.RemoteEvents.building
		if not conn1 then
			conn1 = build_remote.OnServerEvent:Connect(replicator.VerifyAndReplicate)
		end
		
	end
	
	function replicator.VerifyAndReplicate(plrRequestingUpdate : Player, data_table : {})
		local approved_updates = {}
		local rejected_updates = {}
		
		for _, update in pairs(data_table) do
			local chunk = update[1]
			local index = update[2]
			local new_ID = update[4]
			
			
			setmetatable(chunk, require(modules.Chunk))
			
			local range = 10 * configuration.GetVoxelSize()
			
			local remotes = script.Parent.Parent.Remotes
			local building = remotes.RemoteEvents.building

			local i, j, k = Voxel.GetRelPosFromIndex(index)
			local init_corner = chunk:GetInitCorner()
			local x,y,z = utility.Relative_To_World(init_corner, i, j, k)
			local voxel_pos = Vector3.new(x,y,z)

			if not plrRequestingUpdate.Character or not plrRequestingUpdate.Character.PrimaryPart then continue end

			if (voxel_pos - plrRequestingUpdate.Character.PrimaryPart.Position).Magnitude <= range then
				table.insert(approved_updates, update)
				replicator.LogUpdate(chunk, index, new_ID)
			else
				table.insert(rejected_updates, update)
			end
			
			if #approved_updates > 0 then
				building:FireAllClients(plrRequestingUpdate, approved_updates)
			end
			
			if #rejected_updates > 0 then
				building:FireClient(plrRequestingUpdate, nil, rejected_updates)
			end
		end
	end
	
	function replicator.LogUpdate(chunk, index : number, new_ID : number)
		local pos = chunk.Position
		update_log[pos] = update_log[pos] or {}
		update_log[pos][index] = new_ID
	end
	
	function replicator.encodeUpdates()
		local http_service = game:GetService("HttpService")
		return http_service:JSONEncode(update_log)
	end
end 

return replicator