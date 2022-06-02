--!nocheck
local plr : Player = game:GetService('Players').LocalPlayer
local CAS : ContextActionService = game:GetService('ContextActionService')
local UIS : UserInputService = game:GetService('UserInputService')
local modules = require(game:GetService('ReplicatedStorage')["VoxelSea 2.0"].Modules.ModuleIndex)

local replicator = require(modules.ReplicatorAndUpdateLogger)
local configuration = require(modules.Configuration)
local Voxel = require(modules.VoxelLib)
local Chunk = require(modules.Chunk)
local utility = require(modules.Utility)
replicator.InitialiseClient()

local voxariaObjFolder = replicator.VoxariaObjectsFolder

local voxel_size = configuration.GetVoxelSize()
local range = 10 * voxel_size
local cooldown = 0.4

local break_loop : boolean
local buildingCooldown : boolean = false

local function main_handler(action, input_state)

	if input_state == Enum.UserInputState.Begin then
		break_loop = false
	elseif input_state == Enum.UserInputState.End then
		break_loop = true
		return
	end

	if buildingCooldown then print("Had to return"); return end
	buildingCooldown = true

	if action == 'Destroy' then
		repeat

			local mousePos = UIS:GetMouseLocation()
			local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y, 0)
			
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {plr.Character}
			params.FilterType = Enum.RaycastFilterType.Blacklist
			
			local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * range, params)
			
			if results and results.Instance:IsA('BasePart') and results.Instance.Parent == voxariaObjFolder then
				--making sure the voxel can be found by taking the position closer to the voxel's position.
				local hitPos = results.Position - results.Normal * voxel_size/2
				
				local chunk, index = Chunk.GetChunkAndVoxelIndexFromVector3(hitPos)
				local old_ID = chunk.Voxels[index]
				 
				chunk.Voxels[index] = Voxel.GetUpdatedID(chunk.Voxels[index], false, 0)
				chunk:Update()
				replicator.RequestReplication({{chunk, index, old_ID, chunk.Voxels[index]}})
				
			end
			task.wait(cooldown)
		until break_loop
		
	elseif action == 'Build' then
		if input_state == Enum.UserInputState.Begin then
			break_loop = false
		elseif input_state == Enum.UserInputState.End then
			break_loop = true
			return
		end
		
		local current_mat = plr.PlayerGui.Hotbar.CurrentMat.Value
		if current_mat == 0 then break_loop = true; buildingCooldown = false; return end

		repeat
			
			local mousePos = UIS:GetMouseLocation()
			local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y, 0)

			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {plr.Character}
			params.FilterType = Enum.RaycastFilterType.Blacklist

			local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * range, params)

			if results and results.Instance:IsA('BasePart') and results.Instance.Parent == voxariaObjFolder then
				--making sure the voxel can be found by taking the position closer to the voxel's position.
				local hitPos = results.Position + results.Normal * voxel_size/2

				local chunk, index = Chunk.GetChunkAndVoxelIndexFromVector3(hitPos)
				
				local updates = {}
				
				if chunk and index then
					--grass behaviour. checking if terrain block is being placed onto a grass block and if so, removes grass and adds dirt in place of it.
					local i,j,k = Voxel.GetRelPosFromIndex(index)

					local x,y,z = utility.Relative_To_World(chunk:GetInitCorner(), i,j,k)
					y -= voxel_size

					local lower_voxel_pos = Vector3.new(x,y,z)
					local lower_chunk, lower_voxel_index = Chunk.GetChunkAndVoxelIndexFromVector3(lower_voxel_pos)
					
					if lower_chunk then
						local lower_voxel = lower_chunk.Voxels[lower_voxel_index]
						local lower_voxel_mat = Voxel.GetMaterial(lower_voxel)
						if lower_voxel_mat == 1 then
							lower_chunk.Voxels[lower_voxel_index] = Voxel.GetUpdatedID(lower_voxel, Voxel.GetState(lower_voxel), 2)
							lower_chunk:Update()
							table.insert(updates, {lower_chunk, lower_voxel_index, lower_voxel, lower_chunk.Voxels[lower_voxel_index]})
						end
					end

					
					--actual block building
					local old_ID = chunk.Voxels[index]
					
					chunk.Voxels[index] = Voxel.GetUpdatedID(chunk.Voxels[index], false, current_mat)
					chunk:Update()
					table.insert(updates, {chunk, index, old_ID, chunk.Voxels[index]})
					
					 replicator.RequestReplication(updates)
				end
			end
			task.wait(cooldown)
		until break_loop
	end

	task.wait(cooldown/4)
	buildingCooldown = false
end


CAS:BindAction('Destroy', main_handler, false, Enum.KeyCode.R)
CAS:BindAction('Build', main_handler, false, Enum.UserInputType.MouseButton1)


