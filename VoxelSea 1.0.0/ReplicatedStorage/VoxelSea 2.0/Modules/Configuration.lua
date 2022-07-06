local configTable = {}

local chunk_size = script:GetAttribute("ChunkSize") or -1
local vert_chunk_size = script:GetAttribute("VertChunkSize") or -1
local voxel_size = script:GetAttribute("VoxelSize") or -1

function configTable.GetChunkSize() : number
	if chunk_size <= 0 or chunk_size%1 ~= 0 then
		warn("Chunk size must be greater an integer than 0. Chunk size set to 16 voxels.")
		chunk_size = 16
	end
	return chunk_size
end

function configTable.GetVertChunkSize() : number
	if vert_chunk_size <= 0 or vert_chunk_size%1 ~= 0 then
		warn("Vertical chunk size must be greater an integer than 0. Vertical chunk size set to 16 voxels.")
		vert_chunk_size = 16
	end
	return vert_chunk_size
end

function configTable.GetVoxelSize() : number
	if voxel_size <= 0 or voxel_size%1 ~= 0 then
		warn("Voxel size must be an integer greater than 0. Voxel size set to 3 studs.")
		voxel_size = 3
	end

	return voxel_size
end

return configTable