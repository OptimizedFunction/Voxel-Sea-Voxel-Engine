--!nonstrict
local modules = require(script.Parent.ModuleIndex)
local voxel_size : number = require(modules.Configuration).GetVoxelSize()

local module = {}


function module.Relative_To_World(init_corner : Vector3, ...)
	--i, j, k are universally considered relative coords and x, y, z are universally considered world coords across the engine.
	local i, j ,k = ...
	local x : number, y : number, z : number
	local return_table = {}

	if i then
		x = init_corner.X + (i-1/2) * voxel_size
		table.insert(return_table, x)
	end

	if j then
		y = init_corner.Y + (j-1/2) * voxel_size
		table.insert(return_table, y)
	end

	if k then
		z = init_corner.Z + (k-1/2) * voxel_size
		table.insert(return_table, z)
	end
	
	return table.unpack(return_table)
end


function module.World_To_Relative(init_corner : Vector3, ...)
	--i, j, k and x, y, z are as defined in the above function's comment.
	local x, y, z = ...
	local i : number, j : number, k : number
	local return_table = {}

	if x then
		i = (x - init_corner.X)/voxel_size + 1/2
		table.insert(return_table, i)
	end

	if y then
		j = (y - init_corner.Y)/voxel_size + 1/2
		table.insert(return_table, j)
	end

	if z then
		k = (z - init_corner.Z)/voxel_size + 1/2
		table.insert(return_table, k)
	end

	return table.unpack(return_table)
end

return module