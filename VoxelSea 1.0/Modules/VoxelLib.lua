--!nonstrict
local modules = require(script.Parent.ModuleIndex)

local Utility = require(modules.Utility)
local Configuration = require(modules.Configuration)

local chunk_size = Configuration.GetChunkSize()
local vert_chunk_size = Configuration.GetVertChunkSize()
local voxel_size = Configuration.GetVoxelSize()

local Voxel = {}


function Voxel.new(materialCode : number?)
	assert(typeof(materialCode) == 'number' or typeof(materialCode) == nil, '[[Voxaria]][Voxel.new] Argument #1 must be either a number or nil')
	materialCode = materialCode or 0

	local newVoxel = materialCode::number * 10 + 1
	return newVoxel
end


function Voxel.GetState(voxelID : number) : boolean
	assert(typeof(voxelID) == 'number', '[[Voxaria]][Voxel.GetState] Argument #1 must be a number.')
	if voxelID%10 == 0 then return false
	else return true
	end
end

function Voxel.GetOccupationState(voxelID : number) : boolean
	assert(typeof(voxelID) == 'number', '[[Voxaria]][Voxel.GetOccupationState] Argument #1 must be a number.')
end

function Voxel.GetMaterial(voxelID : number) : number
	assert(typeof(voxelID) == 'number', '[[Voxaria]][Voxel.GetMaterial] Argument #1 must be a number.'..typeof(voxelID))
	return math.floor(voxelID/10)
end


function Voxel.GetUpdatedID(voxelID : number, state : boolean?, mat : number?) : number
	assert(typeof(voxelID) == 'number', '[[Voxaria]][Voxel.GetUpdatedID] Argument #1 must be a number.'..typeof(voxelID))
	assert(typeof(state) == 'boolean' or typeof(state) == 'nil', '[[Voxaria]][Voxel.GetUpdatedID] Argument #2 must be either a bool or nil.')
	assert(typeof(mat) == 'number' or typeof(mat) == 'nil', '[[Voxaria]][Voxel.GetUpdatedID] Argument #3 must be either a number or nil.')

	local stateNum : number
	state = state or Voxel.GetState(voxelID)

	if state == true then
		stateNum = 1
	elseif state == false then
		stateNum = 0
	end

	if mat then
		return mat*10 + stateNum
	else 
		return Voxel.GetMaterial(voxelID)*10 + stateNum
	end
end

function Voxel.GetIndex(i : number, j : number, k : number) : number
	assert(typeof(i) == 'number', '[[Voxaria]][Voxel.GetIndex] Argument #1 must be a number.')
	assert(typeof(j) == 'number', '[[Voxaria]][Voxel.GetIndex] Argument #2 must be a number.')
	assert(typeof(k) == 'number', '[[Voxaria]][Voxel.GetIndex] Argument #3 must be a number.')

	return (chunk_size * vert_chunk_size * (k-1)) + (chunk_size * (j-1)) + i
end

function Voxel.GetRelPosFromIndex(index : number) : (number, number, number)
	assert(typeof(index) == 'number', '[[Voxaria]][Voxel.GetRelPosFromIndex] Argument #1 must be a number.')

	local i = index%chunk_size
	local k = math.floor(index/(chunk_size*vert_chunk_size)) + 1
	local j = math.floor((index - (k-1)*chunk_size*vert_chunk_size)/chunk_size) + 1
	
	if i == 0 then
		j -= 1
		i = chunk_size
	end
	
	if j == 0 then 
		k -= 1
		j = vert_chunk_size
	end
	
	return i, j, k
end


function Voxel.GetNearestVoxelPos(vectorPos : Vector3) : Vector3
	assert(typeof(vectorPos) == 'Vector3', '[[Voxaria]][Voxel.GetNearestVoxelPos] Argument #1 must be a Vector3.')

	local x,y,z = CFrame.new(vectorPos + Vector3.new(1,1,1) * math.pi/100):GetComponents()

	local function getSign(num1 : number, num2 : number) : number
		local frac = (num1/num2)%1
		if frac >= 0.5 then return -1
		else return 1
		end
	end

	local pos_x = voxel_size * (math.floor(x/voxel_size + 0.5) + getSign(x, voxel_size)*1/2)
	local pos_y = voxel_size * (math.floor(y/voxel_size + 0.5) + getSign(y, voxel_size)*1/2)
	local pos_z = voxel_size * (math.floor(z/voxel_size + 0.5) + getSign(z, voxel_size)*1/2)

	return Vector3.new(pos_x, pos_y, pos_z)
end

function Voxel.GetVoxelsInCuboid(position : Vector3, size : Vector3) : {{{any} | number}}
	local init_point : Vector3 = Vector3.new(position.X - size.X/2, position.Y - size.Y/2, position.Z - size.Z/2) + Vector3.new(1,1,1)*voxel_size/2
	local final_point : Vector3 = Vector3.new(position.X + size.X/2, position.Y + size.Y/2, position.Z + size.Z/2) - Vector3.new(1,1,1)*voxel_size/2

	local init_voxel_pos : Vector3 = Voxel.GetNearestVoxelPos(init_point)
	local final_voxel_pos : Vector3 = Voxel.GetNearestVoxelPos(final_point)

	local voxelsInCuboid : {{[number] : {any} | number}} = {}

	for x = init_voxel_pos.X, final_voxel_pos.X, voxel_size do
		for y = init_voxel_pos.Y, final_voxel_pos.Y, voxel_size do
			for z = init_voxel_pos.Z, final_voxel_pos.Z, voxel_size do

				local ChunkClass = require(modules.Chunk)
				local chunk, index = ChunkClass.GetChunkAndVoxelIndexFromVector3(Vector3.new(x,y,z))
				
				assert(chunk and index, '[[Voxaria]][GetVoxelsInCuboid] GetChunkAndVoxelIndexFromVector3() experienced an error. chunk and index not found.')
				assert(chunk, '[[Voxaria]][GetVoxelsInCuboid] GetChunkAndVoxelIndexFromVector3() experienced an error. chunk not found.')
				assert(index, '[[Voxaria]][GetVoxelsInCuboid] GetChunkAndVoxelIndexFromVector3() experienced an error. index not found.')

				table.insert(voxelsInCuboid, {chunk, index})
			end
		end
	end
	return voxelsInCuboid
end

function Voxel.GetVoxelsInSphere(center : Vector3, radius : number) : {{{any} | number}}
	local cuboidSize = Vector3.new(1,1,1) * radius * 2

	local voxelsInCircumscribingCuboid = Voxel.GetVoxelsInCuboid(center, cuboidSize)
	local voxelsInSphere = {}

	for _,voxel in pairs(voxelsInCircumscribingCuboid) do
		local chunk = voxel[1]
		local index = voxel[2]

		local voxel_pos = Vector3.new(Utility.Relative_To_World(chunk:GetInitCorner(), Voxel.GetRelPosFromIndex(index)))
		if (voxel_pos - center).Magnitude <= radius then
			table.insert(voxelsInSphere, voxel)
		end
	end
	
	return voxelsInSphere
end

return Voxel




