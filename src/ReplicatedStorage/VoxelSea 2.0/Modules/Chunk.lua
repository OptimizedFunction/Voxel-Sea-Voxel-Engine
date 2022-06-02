--!nonstrict
local modules = require(script.Parent.ModuleIndex)

local replicator = require(modules.ReplicatorAndUpdateLogger)
local config = require(modules.Configuration)
local Voxel = require(modules.VoxelLib)
local ChunkManager = require(modules.ChunkManager)
local utility = require(modules.Utility)
local PoolService = require(modules.PoolService)

local Chunk = {}
Chunk.__index = Chunk

--setting

--[[
If true, Chunk.Load() will error when a chunk position which does not conform/align to the grid is found.

If false, Chunk.Load() will NOT error when a chunk position which does not  conform/align to the grid is
	found. Instead, it will attempt to convert this position into a standard chunk position, which aligns
	with the grid. However, this is not guaranteed and will error if fails.

It is highly recommended to only pass standard grid values to the Chunk.Load() function and not completely
	rely on the in-built safety of the method.
]]
local REJECT_NON_STANDARD_CHUNK_POSITIONS : boolean = false

--other vars
local chunk_size = config.GetChunkSize()
local vert_chunk_size = config.GetVertChunkSize()
local voxel_size = config.GetVoxelSize()


function Chunk.Load(chunkPositions : {Vector3})

	local newChunks = {}

	for i, chunkPosition in pairs(chunkPositions) do
		assert(typeof(chunkPosition) == 'Vector3', '[[Voxel Sea]][Chunk.Load] Argument #1: Unexpected value type found in Vector3 array. Argument #1 must be an array containing only Vector3s.')
		if i%3 == 0 then game:GetService('RunService').Heartbeat:Wait() end

		--not allowing this iteration to go on if the chunk for this chunkPosition already exists.
		if Chunk.GetChunkFromPos(chunkPosition) then
			warn("The chunk at chunk position %s is already loaded.", tostring(chunkPosition))
			continue
		end

		--Converting non-standard chunk position to a standard one. Standard position essentially means aligned/conforming to the grid.
		if not (chunkPosition.X % (voxel_size*chunk_size/2) == chunkPosition.Y % (voxel_size*vert_chunk_size/2) == chunkPosition.Z % (voxel_size*chunk_size/2) == 0) then
			if REJECT_NON_STANDARD_CHUNK_POSITIONS == true then
				error(string.format('[[Voxel Sea]][Chunk.Load] Non-standard chunk position conversion rejected. Rejected chunk position: %s, Nearest valid position: %s', tostring(chunkPosition), tostring(Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(chunkPosition)))))
			else
				local newPos = Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(chunkPosition))

				if not newPos then
					error(string.format('[[Voxel Sea]][Chunk.Load] Failed to convert non-standard chunk position (%s) into a standardised chunk position.', tostring(chunkPosition)))
				else
					chunkPosition = newPos
				end
			end
		end

		local newChunk = {}
		setmetatable(newChunk, Chunk)

		newChunk._IsUpdating = false
		newChunk.Position = chunkPosition
		newChunk.Voxels = table.create(chunk_size^2 * vert_chunk_size, 0)
		newChunk.Parts = {}

		for i = 1, chunk_size do
			for j = 1, vert_chunk_size do
				for k = 1, chunk_size do
					if utility.Relative_To_World(newChunk:GetInitCorner(), nil, j) > vert_chunk_size * voxel_size/2 then
						newChunk.Voxels[Voxel.GetIndex(i, j, k)] = Voxel.new(0)
					elseif Voxel.GetIndex(i, j, k) < 0 then
						newChunk.Voxels[Voxel.GetIndex(i, j, k)] = Voxel.new(3)
					else
						newChunk.Voxels[Voxel.GetIndex(i, j, k)] = Voxel.new(2)
					end

					if utility.Relative_To_World(newChunk:GetInitCorner(), nil, j) == voxel_size * (vert_chunk_size/2-1/2)  then
						newChunk.Voxels[Voxel.GetIndex(i, j, k)] = Voxel.new(1)
					end
				end
			end
		end

		-- ChunkManager.UpdateChunkWithTerrainData(newChunk)

		local loaded_chunks = replicator.LoadedChunkList
		local x,y,z = chunkPosition.X, chunkPosition.Y, chunkPosition.Z

		if not loaded_chunks[x] then loaded_chunks[x] = {} end
		if not loaded_chunks[x][y] then loaded_chunks[x][y] = {} end
		loaded_chunks[x][y][z] = newChunk

		table.insert(newChunks, newChunk)
	end

	local updates : {} = replicator.GetUpdatesForChunks(chunkPositions)
	for _, update_obj in pairs(updates) do
		local chunk = Chunk.GetChunkFromPos(update_obj[1])
		for index, voxel_ID in pairs(update_obj[2]) do
			if tonumber(index) then
				index = tonumber(index)
			else
				error('[[Voxel Sea]][Chunk.Load][Chunk Update] Conversion of index to number using tonumber() failed. Index type: ' .. type(index))
			end
			chunk.Voxels[index] = voxel_ID
		end
	end



	return newChunks
end

function Chunk.LoadAndRender(chunkPosition : Vector3, scheduler, shouldYield : boolean?) --shouldYield is true by default
	if shouldYield == nil then shouldYield = true end
	if not Chunk.GetChunkFromPos(chunkPosition) then Chunk.Load({chunkPosition}) end
	Chunk.GetChunkFromPos(chunkPosition):Render(scheduler, shouldYield :: boolean)
end

function Chunk:RemoveFromView() -- removes all parts associated with the chunk to reduce rendering load. Unloading from
	self:_ClearParts()			-- the memory is done using Chunk:Unload() which also frees up memory.
	local list = replicator.RenderedChunkList
	table.remove(list, table.find(list, self))
end

function Chunk:Unload() -- prepares chunk object for garbage collection.
	local pos_x, pos_y, pos_z = CFrame.new(self.Position):GetComponents()

	local list = replicator.LoadedChunkList
	if list[pos_x] and list[pos_x][pos_y] and list[pos_x][pos_y][pos_z] then
		list[pos_x][pos_y][pos_z] = nil
	end

	self:_ClearParts()
	self.Parts = nil
	self.Voxels = nil

	local metatable = {
		__index = function()
			error('[[Voxel Sea]][Chunk] Attempt to access unloaded chunk!')
		end;
		__newindex = function()
			error('[[Voxel Sea]][Chunk] Attempt to access unloaded chunk!')
		end;
	}

	setmetatable(self, metatable)
	self = nil
end

function Chunk.IsChunkAtPositionRendered(chunkPos : Vector3) : boolean
	local chunk = Chunk.GetChunkFromPos(chunkPos)
	if chunk then

		if table.find(replicator.RenderedChunkList, chunk) then
			return true
		else
			return false
		end

	else
		return false
	end
end

function Chunk:GetInitCorner() : Vector3
	local chunkPosition = self.Position
	local chunk_size_in_studs = chunk_size * voxel_size
	local vert_chunk_size_in_studs = vert_chunk_size * voxel_size
	return Vector3.new(chunkPosition.X - chunk_size_in_studs/2, chunkPosition.Y - vert_chunk_size_in_studs/2, chunkPosition.Z - chunk_size_in_studs/2)
end


function Chunk:_GetNumOfAirVoxels() : number
	local air_voxels = 0
	for _,voxel in ipairs(self.Voxels) do
		if Voxel.GetMaterial(voxel) == 0 then
			air_voxels += 1
		end
	end
	return air_voxels
end

function Chunk:_GetNumOfActiveVoxels() : number
	local active_voxels = 0
	for _,voxel in ipairs(self.Voxels) do
		if Voxel.GetState(voxel) then
			active_voxels += 1
		end
	end
	return active_voxels
end



function Chunk:_ClearParts()
	if not self.Parts then return end
	for _, part in ipairs(self.Parts) do
		PoolService.AddPart(part)
	end
	table.clear(self.Parts)
end



function Chunk:_ResetVoxelStateToInactive()
	for index, voxel in ipairs(self.Voxels) do
		self.Voxels[index] = Voxel.GetUpdatedID(voxel, false)
	end
end

function Chunk:_ResetVoxelStateToActive()
	for index, voxel in ipairs(self.Voxels) do
		self.Voxels[index] = Voxel.GetUpdatedID(voxel, true)
	end
end

function Chunk.GetChunkFromPos(chunkPos : Vector3) : {} | nil
	local x,y,z = CFrame.new(chunkPos):GetComponents()
	local loaded_chunk_list = replicator.LoadedChunkList

	if loaded_chunk_list[x] and loaded_chunk_list[x][y] and loaded_chunk_list[x][y][z] then
		return loaded_chunk_list[x][y][z]
	else
		return nil
	end
end

function Chunk.GetChunkPosFromVoxelPos(voxel_pos : Vector3) : Vector3
	local chunk_size_in_studs = chunk_size * voxel_size
	local vert_chunk_size_in_studs = vert_chunk_size * voxel_size

	local x,y,z = CFrame.new(voxel_pos + Vector3.new(1,1,1) * math.pi/100):GetComponents()

	local function getSign(num1 : number, num2 : number) : number
		local frac = (num1/num2)%1
		if frac >= 0.5 then return -1
		else return 1
		end
	end

	local pos_x = chunk_size_in_studs * (math.floor(x/chunk_size_in_studs + 0.5) + getSign(x, chunk_size_in_studs)*1/2)
	local pos_y = vert_chunk_size_in_studs * (math.floor(y/vert_chunk_size_in_studs + 0.5) + getSign(y, vert_chunk_size_in_studs)*1/2)
	local pos_z = chunk_size_in_studs * (math.floor(z/chunk_size_in_studs + 0.5) + getSign(z, chunk_size_in_studs)*1/2)

	return Vector3.new(pos_x, pos_y, pos_z)
end

function Chunk.GetChunkFromVoxelPos(voxel_pos : Vector3) : {} | nil
	assert(typeof(voxel_pos) == 'Vector3', '[[Voxel Sea]][Chunk.GetChunkFromVoxelPos] Argument #1 must be a Vector3.')
	return Chunk.GetChunkFromPos(Chunk.GetChunkPosFromVoxelPos(voxel_pos))
end

function Chunk.GetChunkAndVoxelIndexFromVector3(vectorPos : Vector3) : ( {} | nil, number | nil ) --returns the chunk and index of the voxel the vectorPos lies in.
	assert(typeof(vectorPos) == 'Vector3', '[[Voxel Sea]][Chunk.GetChunkAndVoxelIndexFromVector3] Argument #1 must be a Vector3.')

	local voxel_pos = Voxel.GetNearestVoxelPos(vectorPos)
	local chunk = Chunk.GetChunkFromVoxelPos(voxel_pos)

	if not chunk then
		return
	end

	local index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), CFrame.new(voxel_pos):GetComponents()))
	return chunk, index
end


--the main checking loop for compact and render function.
function _Voxel_Combination_loop(chunk, visited_voxels : {boolean}, init_i : number, init_j : number, init_k : number, init_mat : number) : (number, number, number)
	local voxels = chunk.Voxels

	local function Get_max_i()
		for i = init_i+1, chunk_size do
			local index = Voxel.GetIndex(i, init_j, init_k)
			local voxel = voxels[index]
			if visited_voxels[index] then
				return i-1
			else
				if Voxel.GetMaterial(voxel) == init_mat then
					continue
				else
					return i-1
				end
			end
		end
		return chunk_size
	end

	local function Get_max_j(max_i)
		for j = init_j+1, vert_chunk_size do
			for i = init_i, max_i do
				local index = Voxel.GetIndex(i, j, init_k)
				local voxel = voxels[index]
				if visited_voxels[index] then
					return j-1
				else
					if Voxel.GetMaterial(voxel) == init_mat then
						continue
					else
						return j-1
					end
				end
			end
		end
		return vert_chunk_size
	end

	local function Get_max_k(max_i, max_j)

		for k = init_k+1, chunk_size do
			for j = init_j, max_j do
				for i = init_i, max_i do
					local index = Voxel.GetIndex(i, j, k)
					local voxel = voxels[index]
					if visited_voxels[index] then
						return k-1
					else
						if Voxel.GetMaterial(voxel) == init_mat then
							continue
						else
							return k-1
						end
					end
				end
			end
		end
		return chunk_size
	end

	local Max_i = Get_max_i()
	local Max_j = Get_max_j(Max_i)
	local Max_k = Get_max_k(Max_i, Max_j)

	return Max_i, Max_j, Max_k
end

function Chunk:CompactAndRender()
	--greedy meshing function.

	local init_corner : Vector3 = self:GetInitCorner()
	local initial_voxel_found = false
	local voxels = self.Voxels

	local rendered_chunk_list = replicator.RenderedChunkList

	local visited_voxels : {boolean} = table.create(chunk_size^2 * vert_chunk_size, false)
	local part_list : {BasePart} = {}

	self:_ResetVoxelStateToActive()

	while true do
		-- finding eligible initial voxel
		initial_voxel_found = false
		local init_i : number, init_j : number, init_k : number
		local init_index : number
		local init_mat : number = 0

		for index, voxel in pairs(voxels) do
			if Voxel.GetState(voxel) and not visited_voxels[index] then
				visited_voxels[index] = true

				if Voxel.GetMaterial(voxel) == 0 then
					continue
				end

				init_i, init_j, init_k = Voxel.GetRelPosFromIndex(index)
				init_mat = Voxel.GetMaterial(voxel)
				initial_voxel_found = true
				break
			end
		end


		if not initial_voxel_found or not (init_i and init_j and init_k) then break end
		--the main checking loop
		local checked_i, checked_j, checked_k = _Voxel_Combination_loop(self, visited_voxels, init_i, init_j, init_k, init_mat)

		local init_x, init_y, init_z = utility.Relative_To_World(init_corner, init_i, init_j, init_k)
		local final_x, final_y, final_z = utility.Relative_To_World(init_corner, checked_i, checked_j, checked_k)


		local part_size_x = math.abs(init_x - final_x) + voxel_size
		local part_size_y = math.abs(init_y - final_y) + voxel_size
		local part_size_z = math.abs(init_z - final_z) + voxel_size


		local part_pos_x = init_x + (math.abs(init_x - final_x) * 0.5)
		local part_pos_y = init_y + (math.abs(init_y - final_y) * 0.5)
		local part_pos_z = init_z + (math.abs(init_z - final_z) * 0.5)


		local part_size = Vector3.new(part_size_x, part_size_y, part_size_z)
		local part_pos = Vector3.new(part_pos_x, part_pos_y, part_pos_z)

		--making the part and setting textures
		local voxel_part : Part
		if #self.Parts > 0 then
			for i = 1, #self.Parts do
				if self.Parts[i]:GetAttribute('MaterialCode') == init_mat then
					voxel_part = self.Parts[i]
					voxel_part.Position = part_pos
					voxel_part.Size = part_size

					table.remove(self.Parts, i)
					break
				end
			end

			if not voxel_part then
				voxel_part = self.Parts[1]
				voxel_part.Position = part_pos
				voxel_part.Size = part_size

				PoolService.AddTexturesToPool(voxel_part)

				voxel_part:SetAttribute('MaterialCode', init_mat)
				PoolService.AddTexturesToPart(voxel_part, init_mat)

				table.remove(self.Parts, 1)
			end
		else
			voxel_part = PoolService.GetPart(part_pos, part_size, init_mat)
		end

		if voxel_part.Parent ~= replicator.VoxariaObjectsFolder then
			voxel_part.Parent = replicator.VoxariaObjectsFolder
		end

		table.insert(part_list, voxel_part)

		for a = init_i, checked_i do
			for b = init_j, checked_j do
				for c = init_k, checked_k do
					local index = Voxel.GetIndex(a,b,c)
					if not visited_voxels[index] then
						visited_voxels[index] = true
					end
				end
			end
		end

	end

	self:_ClearParts()
	self.Parts = part_list

	if not table.find(rendered_chunk_list, self) then
		table.insert(rendered_chunk_list, self)
	end

	self._IsUpdating = false
end


function Chunk:FilterInternalVoxels() --  Good when number of air voxels are more.

	self._IsUpdating = true

	local init_corner = self:GetInitCorner()
	local voxels = self.Voxels

	for i = 1, chunk_size do
		for j = 1, vert_chunk_size do
			for k = 1, chunk_size do

				local index = Voxel.GetIndex(i, j, k)
				local voxel = voxels[index]
				if Voxel.GetMaterial(voxel) == 0 then
					continue
				else
					local should_be_active = false

					for a =  -1, 1, 2 do
						local voxel_pos = Vector3.new(utility.Relative_To_World(init_corner, i+a, j, k))
						local chunk = self

						if i+a < 1 or i+a > chunk_size then
							should_be_active = true
							break
						end

						local neighbor_voxel_index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), voxel_pos.X, voxel_pos.Y, voxel_pos.Z) )
						local neighbor_voxel = chunk.Voxels[neighbor_voxel_index]
						if Voxel.GetMaterial(neighbor_voxel) ~= 0 then
							continue
						else
							should_be_active = true
							break
						end
					end

					for b = -1, 1, 2 do
						local voxel_pos = Vector3.new(utility.Relative_To_World(init_corner, i, j+b, k))
						local chunk = self


						if j+b < 1 or j+b > vert_chunk_size then
							should_be_active = true
							break
						end

						local neighbor_voxel_index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), voxel_pos.X, voxel_pos.Y, voxel_pos.Z))
						local neighbor_voxel = chunk.Voxels[neighbor_voxel_index]
						if Voxel.GetMaterial(neighbor_voxel) ~= 0 then
							continue
						else
							should_be_active = true
							break
						end
					end

					for c = -1, 1, 2 do
						local voxel_pos = Vector3.new(utility.Relative_To_World(init_corner, i, j, k+c))
						local chunk = self

						if k+c < 1 or k+c > chunk_size then
							should_be_active = true
							break
						end

						local neighbor_voxel_index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), voxel_pos.X, voxel_pos.Y, voxel_pos.Z))
						local neighbor_voxel = chunk.Voxels[neighbor_voxel_index]
						if Voxel.GetMaterial(neighbor_voxel) ~= 0 then
							continue
						else
							should_be_active = true
							break
						end
					end

					if not should_be_active then
						voxels[index] = Voxel.GetUpdatedID(voxel, false)
					end

				end
			end
		end
	end
end

function Chunk:FilterInternalVoxels2() -- good when number of non-air voxels is high.

	self:ResetVoxelStateToInactive()
	self._IsUpdating = true

	local init_corner = self:GetInitCorner()
	local voxels = self.Voxels

	for i = 1, chunk_size do
		for j = 1, vert_chunk_size do
			for k = 1, chunk_size do

				local index = Voxel.GetIndex(i, j, k)
				local voxel = voxels[index]

				if (i == 1 or i == chunk_size or j == 1 or j == chunk_size or k == 1 or k == chunk_size) and Voxel.GetMaterial(voxel) ~= 0 then
					voxels[index] = Voxel.GetUpdatedID(voxel, true)

				elseif Voxel.GetMaterial(voxel) ~= 0 then
					continue

				else
					for a =  -1, 1, 2 do
						local voxel_pos = Vector3.new(utility.Relative_To_World(init_corner, i+a, j, k))
						local chunk = self

						if i+a < 1 or i+a > chunk_size then
							continue
						end

						local neighbor_voxel_index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), voxel_pos.X, voxel_pos.Y, voxel_pos.Z) )
						local neighbor_voxel = chunk.Voxels[neighbor_voxel_index]
						if Voxel.GetMaterial(neighbor_voxel) ~= 0 then
							chunk.Voxels[neighbor_voxel_index] = Voxel.GetUpdatedID(neighbor_voxel, true)
						end
					end

					for b = -1, 1, 2 do
						local voxel_pos = Vector3.new(utility.Relative_To_World(init_corner, i, j+b, k))
						local chunk = self

						if j+b < 1 or j+b > chunk_size then
							continue
						end

						local neighbor_voxel_index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), voxel_pos.X, voxel_pos.Y, voxel_pos.Z) )
						local neighbor_voxel = chunk.Voxels[neighbor_voxel_index]
						if Voxel.GetMaterial(neighbor_voxel) ~= 0 then
							chunk.Voxels[neighbor_voxel_index] = Voxel.GetUpdatedID(neighbor_voxel, true)
						end
					end
					for c = -1, 1, 2 do
						local voxel_pos = Vector3.new(utility.Relative_To_World(init_corner, i, j, k+c))
						local chunk = self

						if k+c < 1 or k+c > chunk_size then
							continue
						end

						local neighbor_voxel_index = Voxel.GetIndex(utility.World_To_Relative(chunk:GetInitCorner(), voxel_pos.X, voxel_pos.Y, voxel_pos.Z) )
						local neighbor_voxel = chunk.Voxels[neighbor_voxel_index]
						if Voxel.GetMaterial(neighbor_voxel) ~= 0 then
							chunk.Voxels[neighbor_voxel_index] = Voxel.GetUpdatedID(neighbor_voxel, true)
						end
					end

				end
			end
		end
	end
end


function Chunk:Render(scheduler, shouldYield : boolean?) -- Renders chunk. shouldYield param is optional. Defines if the
															  -- lua thread which called this method be yielded or not.
	if not scheduler then error('Scheduler object is required to render chunk.') end
	scheduler:QueueTask(function() self:CompactAndRender() end, shouldYield)
end

function Chunk:Update()
	coroutine.wrap(function()
		repeat game:GetService('RunService').RenderStepped:Wait()
		until not self._IsUpdating
		self:CompactAndRender()
	end)()
end

return Chunk