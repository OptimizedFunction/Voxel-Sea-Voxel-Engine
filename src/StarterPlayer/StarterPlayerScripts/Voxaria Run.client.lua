--!nonstrict
local modules = require(game:GetService('ReplicatedStorage')["VoxelSea 2.0"].Modules.ModuleIndex)

local replicator = require(modules.ReplicatorAndUpdateLogger)
local Voxel = require(modules.VoxelLib)
local Chunk = require(modules.Chunk)
local ChunkManager = require(modules.ChunkManager)
local TS = require(modules.TaskScheduler)
local configuration = require(modules.Configuration)

replicator:InitialiseClient()
Chunk.SetLoadDataCallback(ChunkManager.UpdateChunkWithTerrainData)

local CS_inStuds = configuration.GetChunkSize() * configuration.GetVoxelSize()
local VCS_inStuds = configuration.GetVertChunkSize() * configuration.GetVoxelSize()

local init_render_dist = 4
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local run_service = game:GetService("RunService")

local max_render_dist_txtBox : TextBox = game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Misc'):WaitForChild('RenderDistanceLabel'):WaitForChild('RenderDistanceInput')
local max_render_dist : number =  tonumber(max_render_dist_txtBox.Text) or 4


local scheduler = TS:CreateScheduler(35)

local plr = game:GetService('Players').LocalPlayer
repeat task.wait(1) until plr.Character ~= nil


max_render_dist_txtBox:GetPropertyChangedSignal('Text'):Connect(function()
    if not max_render_dist_txtBox.Text then return end
    local newRenderDist = math.floor(tonumber(max_render_dist_txtBox.Text))
    if newRenderDist then
        max_render_dist = math.clamp(newRenderDist, 3, 16)

        local char : Model = plr.Character or plr.CharacterAdded:Wait()
        local rootPart : Part = char:WaitForChild('HumanoidRootPart')

        local ModifiedPrimaryPartPos : Vector3 = rootPart.Position + Vector3.new(1,1,1) * configuration.GetVoxelSize() * math.pi/100
        local originChunkPos : Vector3 = Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(ModifiedPrimaryPartPos))

        render_loop(originChunkPos)
    end
end)


print('loading chunk data.')
local init_time = os.clock()

local init_chunks = {}

for a = -init_render_dist, init_render_dist-1 do
    for b = -init_render_dist, init_render_dist-1 do

        local centerPos = Vector3.new(1,1,1) * configuration.GetVoxelSize() * math.pi/100
        local originChunkPos = Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(centerPos))

        local pos = originChunkPos + (Vector3.new(a,0,b) + Vector3.new(1/2,0,1/2)) * CS_inStuds

        if not Chunk.GetChunkFromPos(pos) then
            table.insert(init_chunks, pos)
        else
            continue
        end

    end
end

print(os.clock() - init_time)

task.wait(1)

init_time = os.clock()
print('scheduling render requests now!')



for _, chunk in pairs(Chunk.Load(init_chunks)) do
    chunk:Render(scheduler, true)
end

local event = ReplicatedFirst.LoadedEvent
event:Fire()


local time_taken = os.clock() - init_time
print(time_taken)


plr.CameraMaxZoomDistance = 1000
--plr.CameraMode = Enum.CameraMode.LockFirstPerson

local chunks_in_range = {}
local chunks_to_load = {}
function render_loop(originChunkPos : Vector3)

    scheduler:ClearQueue()

    chunks_in_range = {}
    chunks_to_load = {}

    for max_length = 1, max_render_dist do
        for direction = 1, -1, -2 do

            for current_i = -max_length, max_length-1 do
                local current_x = direction * current_i * CS_inStuds + originChunkPos.X
                local current_y = VCS_inStuds/2
                local current_z = direction * (max_length - 1) * CS_inStuds + originChunkPos.Z

                local pos = Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(Vector3.new(current_x, current_y, current_z)))

                table.insert(chunks_in_range, pos)
                if not Chunk.IsChunkAtPositionRendered(pos) then
                    table.insert(chunks_to_load, pos)
                end
            end

            for current_k = -max_length, max_length-1 do
                local current_x = direction * (max_length - 1) * CS_inStuds + originChunkPos.X
                local current_y = VCS_inStuds/2
                local current_z = -direction * current_k * CS_inStuds + originChunkPos.Z

                local pos = Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(Vector3.new(current_x, current_y, current_z)))

                table.insert(chunks_in_range, pos)
                if not Chunk.IsChunkAtPositionRendered(pos) then
                    table.insert(chunks_to_load, pos)
                end
            end

        end
    end



    for _, chunkPos in pairs(chunks_to_load) do
        Chunk.LoadAndRender(chunkPos, scheduler)
    end
end

function unloading_loop(originChunkPos : Vector3)
    if #chunks_in_range > 0 then
        for x, a in pairs(replicator.LoadedChunkList) do
            for y, b in pairs(a) do
                for z, chunk in pairs(b) do
                    if not table.find(chunks_in_range, Vector3.new(x,y,z)) then
                        chunk:RemoveFromView()
                        if (Vector3.new(x,y,z) - originChunkPos).Magnitude > (max_render_dist + 2) * math.sqrt(2) * CS_inStuds then
                            chunk:Unload()
                            run_service.Heartbeat:Wait()
                        end
                    end
                end
            end
        end
    end
end

local oldOriginChunkPos : Vector3

while true do
    local char = plr.Character or plr.CharacterAdded
    local rootPart = char:WaitForChild("HumanoidRootPart")

    local ModifiedPrimaryPartPos : Vector3 = rootPart.Position + Vector3.new(1,1,1) * configuration.GetVoxelSize() * math.pi/100
    local originChunkPos : Vector3 = Chunk.GetChunkPosFromVoxelPos(Voxel.GetNearestVoxelPos(ModifiedPrimaryPartPos))

    if oldOriginChunkPos and originChunkPos ~= oldOriginChunkPos then
        task.spawn(unloading_loop, originChunkPos)
        render_loop(originChunkPos)
    end

    oldOriginChunkPos = originChunkPos

    task.wait(0.25)
end