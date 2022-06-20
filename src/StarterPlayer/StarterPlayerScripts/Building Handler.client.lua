--!nocheck
local plr : Player = game:GetService('Players').LocalPlayer
local CAS : ContextActionService = game:GetService('ContextActionService')
local UIS : UserInputService = game:GetService('UserInputService')
local RunService : RunService = game:GetService('RunService')
local modules = require(game:GetService('ReplicatedStorage')["VoxelSea 2.0"].Modules.ModuleIndex)

local replicator = require(modules.ReplicatorAndUpdateLogger)
local configuration = require(modules.Configuration)
local Voxel = require(modules.VoxelLib)
local Chunk = require(modules.Chunk)
local utility = require(modules.Utility)
replicator.InitialiseClient()

local voxariaObjFolder = replicator.VoxariaObjectsFolder
local currentBrush = nil
local currentPos = Vector3.new()

local voxel_size = configuration.GetVoxelSize()
local range = 20 * voxel_size
local cooldown = 0.4

local break_loop : boolean
local buildingCooldown : boolean = false

local function main_handler(action, input_state)

	break_loop = true
	if input_state == Enum.UserInputState.End then
		return
	end

	if buildingCooldown then return end
	buildingCooldown = true

	if action == 'Destroy' then
		break_loop = false
		repeat
			local chunk, index = Chunk.GetChunkAndVoxelIndexFromVector3(currentPos)
			if not chunk then warn("Chunk not found!"); break; end

			local old_ID = chunk.Voxels[index]
			chunk.Voxels[index] = Voxel.GetUpdatedID(chunk.Voxels[index], false, 0)
			chunk:Update()
			replicator.RequestReplication({{chunk, index, old_ID, chunk.Voxels[index]}})

			task.wait(cooldown)
		until break_loop
		
	elseif action == 'Build' then
		break_loop = false
		local current_mat = plr.PlayerGui.Hotbar.CurrentMat.Value
		if current_mat == 0 then break_loop = true; buildingCooldown = false; return end

		repeat
			local mousePos = UIS:GetMouseLocation()
			local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y, 0)
			
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {currentBrush, plr.Character or plr.CharacterAdded:Wait()}
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

function updateBrush(position : Vector3)
    local brush : Part
    if currentBrush and (currentBrush:FindFirstChild('SelectionBox')) then
        brush = currentBrush
		currentPos = position
        brush.Position = position

        local selectionInstance = currentBrush:FindFirstChild('SelectionBox')
        selectionInstance.Color3 = Color3.new(0, 0, 0)
    else
        brush = Instance.new('Part')
		brush.CanCollide = false
	    brush.Transparency = 1
		currentPos = position
        brush.Position = position
        brush.Name = '[VoxelSea] BoundingPart'
        brush.Locked = true
		brush.Anchored = true
        brush.Parent = workspace
        brush.Size = Vector3.new(1.1, 1.1, 1.1) * voxel_size

        local SelectionBox = Instance.new('SelectionBox')
        SelectionBox.SurfaceTransparency = 1
		SelectionBox.Transparency = 0.5
		SelectionBox.Color3 = Color3.new(0, 0, 0)
        SelectionBox.Adornee = brush
        SelectionBox.LineThickness = 0.001
        SelectionBox.Parent = brush
    end
    return brush
end

--actual build function
RunService:BindToRenderStep(
	"SelectionBinding",
	Enum.RenderPriority.Input.Value - 1,
	function()
		local mousePos = UIS:GetMouseLocation()
		local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y, 0)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {currentBrush, plr.Character or plr.CharacterAdded:Wait()}
		params.FilterType = Enum.RaycastFilterType.Blacklist

		local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * range, params)


		if results and results.Instance:IsA('BasePart') then
			local hitPos : Vector3 = results.Position - results.Normal * voxel_size/2
			local x,y,z = CFrame.new(hitPos):GetComponents()

			local function getSign(num1 : number, num2 : number, num3 : number) : number
				if num2%2 == 0 then 
					return 0    
				end

				local frac = (num1/num3)%1
				if frac >= 0.5 then return -1
				else return 1
				end
			end

			
			local pos_x = voxel_size * (math.floor(x/voxel_size + 0.5) + getSign(x, 1, voxel_size)*1/2)
			local pos_y =  voxel_size * (math.floor(y/voxel_size + 0.5) + getSign(y, 1, voxel_size)*1/2)
			local pos_z = voxel_size * (math.floor(z/voxel_size + 0.5) + getSign(z, 1, voxel_size)*1/2)

			local box_pos = Vector3.new(pos_x, pos_y, pos_z)

			currentBrush = updateBrush(box_pos)
		end

	end
)
