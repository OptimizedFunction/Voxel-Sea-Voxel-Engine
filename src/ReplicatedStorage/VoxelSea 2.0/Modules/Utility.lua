--!nonstrict
local modules = require(script.Parent.ModuleIndex)
local voxel_size : number = require(modules.Configuration).GetVoxelSize()

local module = {}


function module.Relative_To_World(init_corner : Vector3, ...)
	--i, j, k are universally considered relative coords and x, y, z are universally considered world coords across the engine.
	local i, j ,k = ...
	local x : number, y : number, z : number
	

	if i then x = init_corner.X + (i-1/2) * voxel_size end
	if j then y = init_corner.Y + (j-1/2) * voxel_size end
	if k then z = init_corner.Z + (k-1/2) * voxel_size end

	
	if x and y and z then return x,y,z
	elseif x and y and not z then return x,y
	elseif x and not y and z then return x,z
	elseif not x and y and z then return y,z
	elseif not (x or y) and z then return z
	elseif not (x or z) and y then return y
	elseif x and not (y or z) then return x
	end
end


function module.World_To_Relative(init_corner : Vector3, ...)
	--i, j, k and x, y, z are as defined in the above function's comment.
	local x, y, z = ...
	local i : number, j : number, k : number
	

	if x then i = (x - init_corner.X)/voxel_size + 1/2 end
	if y then j = (y - init_corner.Y)/voxel_size + 1/2 end
	if z then k = (z - init_corner.Z)/voxel_size + 1/2 end

	if i and j and k then return i,j,k
	elseif i and j and not k  then return i,j
	elseif i and not j and k then return i,k
	elseif not i and j and k then return j,k
	elseif not (i or j) and k then return k
	elseif not (i or k) and j then return j
	elseif i and not (j or k) then return i
	end
end

return module