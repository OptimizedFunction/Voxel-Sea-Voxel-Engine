local HttpService: HttpService = game:GetService("HttpService")

local seed = script.Parent:GetAttribute("seed")
local index = script.Parent:GetAttribute("index")

local vert_chunk_size = script.Parent:GetAttribute("vert_chunk_size")
local chunk_size = script.Parent:GetAttribute("chunk_size")
local voxel_size = script.Parent:GetAttribute("voxel_size")
local init_corner = script.Parent:GetAttribute("init_corner")


function GenerateHeightMapForPart()
	local height_map
	local scale = 0.65
	local octaves = 4
	local frequency = 600
	local amplitude = vert_chunk_size * 3/4
	local persistence = 0.35
	local lacunarity = 2
	
	local i = index%chunk_size
	local k = math.floor(index/chunk_size)
	i = if i == 0 then chunk_size else i
	k = if k == 0 then chunk_size else k

	
	local x = Relative_To_World(init_corner, i, nil, nil)
	local y : number = 0
	local z = Relative_To_World(init_corner, nil, nil, k)

	local amp = amplitude
	local freq = frequency

	for _ = 1, octaves do
		y = y + (amp * scale * (math.noise((x + seed)/freq, (z + seed)/freq)))
		freq = freq / lacunarity
		amp = amp * persistence
	end

	y = voxel_size * math.floor(math.floor(vert_chunk_size/2) + y)
	height_map = math.ceil(y/voxel_size)

	
	task.synchronize()
	script.Parent:SetAttribute("heightMapVal", height_map)
	script.Parent.ComputationCompleted:Fire()
	script.Enabled = false
end


function Relative_To_World(init_corner : Vector3, ...)
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

task.desynchronize()
GenerateHeightMapForPart()