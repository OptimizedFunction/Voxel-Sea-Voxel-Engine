--!nonstrict
local modules = require(script.Parent.ModuleIndex)

local config = require(modules.Configuration)
local Voxel = require(modules.VoxelLib)
local assetManager = require(modules.AssetManager)
local utility = require(modules.Utility)


local chunk_size = config.GetChunkSize()
local vert_chunk_size = config.GetVertChunkSize()
local voxel_size = config.GetVoxelSize()


local seed : number = math.random() * 10


local mat_info = assetManager.Material_Info
local materials = {}

for _, mat in pairs(mat_info) do
    materials[mat.Name] = mat.Code
end


local chunk_manager = {}

function chunk_manager.UpdateChunkWithTerrainData(chunk)

    local init_corner = chunk:GetInitCorner()

    local default_Air_threshold : number = 0.3
    local default_Dirt_threshold : number = 0.9

    local max_Dirt_threshold : number = 0.95

    local Air_threshold : number = default_Air_threshold
    local Dirt_threshold : number = default_Dirt_threshold
    local Stone_threshold : number = 1


    local function isAir(x : number, y : number, z : number, divider : number) : boolean
        local noise = math.noise(x/divider + seed, y/divider + seed, z/divider + seed)
        noise = math.clamp(noise,-0.5,0.5)
        if noise < Air_threshold - 0.5 then
            return true
        else
            return false
        end
    end




    local function GenerateHeightMap()
        local height_map = {}
        local scale = 0.65
        local octaves = 4
        local frequency = 600
        local amplitude = vert_chunk_size * 3/4
        local persistence = 0.35
        local lacunarity = 2

        for i = 1, chunk_size do
            local x = utility.Relative_To_World(init_corner, i)
            for k = 1, chunk_size do
                local y : number = 0
                local z = utility.Relative_To_World(init_corner, nil, nil, k)

                local amp = amplitude
                local freq = frequency

                for _ = 1, octaves do
                    y = y + (amp * scale * (math.noise((x + seed)/freq, (z + seed)/freq)))
                    freq = freq / lacunarity
                    amp = amp * persistence
                end
                
                y = voxel_size * math.floor(math.floor(vert_chunk_size/2) + y)
                height_map[i] = height_map[i] or {}
                height_map[i][k] = math.ceil(y/voxel_size)
            end
        end
        return height_map
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
