local PartPool = {}
local TexturePool = script:WaitForChild('TexturePool')

local modules = require(script.Parent.Parent.ModuleIndex)

local replicator = require(modules.ReplicatorAndUpdateLogger)
local assetManager = require(modules.AssetManager)
local debrisCollector = require(modules.DebrisCollector)
local configuration = require(modules.Configuration)

local PARTS_POOL_CAP : number = math.floor(configuration.GetChunkSize()^2 * configuration.GetVertChunkSize() * 0.3)

local tempPartLifetime : number = 60        --in seconds
local tempTextureLifetime : number = 30     --in seconds

local poolService = {}

function poolService.AddPart(part : Part)
    assert(typeof(part) == 'Instance' and part:IsA('Part'), '[[Voxaria]][PoolService][.AddPart] Argument #1 must be a Part Instance.')
    
    if part.Parent ~= nil then
        table.insert(PartPool, part)
        part.CFrame = CFrame.new(0, math.huge, 0)
    else
        return
    end

    local matCode : number = part:GetAttribute('MaterialCode')
    if not matCode then error('Material Code attribute does not exist for part '..part:GetFullName()) end

    local matName : string = assetManager.GetNameFromMaterialCode(matCode)

    if #PartPool >= PARTS_POOL_CAP then
        debrisCollector.AddItem(part, tempPartLifetime)
    end


    local matFolder = TexturePool:FindFirstChild(matName)
    if not matFolder then
        matFolder = Instance.new('Folder')
        matFolder.Name = matName
        matFolder.Parent = TexturePool
    end

    local matFolderPartition = Instance.new('Folder', matFolder)
    debrisCollector.AddItem(matFolderPartition, tempTextureLifetime)

    for _,child in pairs(part:GetChildren()) do
        if child:IsA('Texture') then
            child.Parent = matFolderPartition
        end
    end
end

function poolService.GetPart(position : Vector3, size : Vector3, matCode : number) : Part
    assert(typeof(position) == 'Vector3', '[[Voxaria]][PoolService][.GetPart] Argument #1 must be a Vector3.')
    assert(typeof(size) == 'Vector3', '[[Voxaria]][PoolService][.GetPart] Argument #2 must be a Vector3.')
    assert(typeof(matCode) == 'number', '[[Voxaria]][PoolService][.GetPart] Argument #3 must be a number.')


    local part : Part
    if #PartPool > 0 then
		part = table.remove(PartPool, 1)
       	debrisCollector.RemoveItem(part)
    else
        part = Instance.new('Part')
        part.Name = 'Compacted_Part'
        part.Material = Enum.Material.Concrete
        part.Anchored = true
    end

    part.Position = position
    part.Size = size
    part:SetAttribute('MaterialCode', matCode)
    part.Parent = replicator.VoxariaObjectsFolder

    local matName : string = assetManager.GetNameFromMaterialCode(matCode)

    local matFolder = TexturePool:FindFirstChild(matName)
    if not matFolder or #matFolder:GetChildren() == 0 then
        local textures : {Texture} = assetManager.GetTextureCopies(matCode)
        for _, texture in pairs(textures) do
            texture.Parent = part
        end
    else
        local partitionFolder : Instance = matFolder:FindFirstChildOfClass('Folder')
        debrisCollector.RemoveItem(partitionFolder)

        for _, texture in pairs(partitionFolder:GetChildren()) do
            texture.Parent = part
        end
        partitionFolder:Destroy()
    end

    return part
end


function poolService.AddTexturesToPool(part: Part)
    assert(typeof(part) == 'Instance' and part:IsA('Part'), '[[Voxaria]][PoolService][.PoolTexturesFromPart] Argument #1 must be a Part Instance.')

    local matName : string = assetManager.GetNameFromMaterialCode(part:GetAttribute('MaterialCode'))
    
    local matFolder = TexturePool:FindFirstChild(matName)
    if not matFolder then
        matFolder = Instance.new('Folder')
        matFolder.Name = matName
        matFolder.Parent = TexturePool
    end

    local matFolderPartition = Instance.new('Folder', matFolder)
    matFolderPartition.Name = #matFolder:GetChildren()
    debrisCollector.AddItem(matFolderPartition, tempTextureLifetime)

    for _,child in pairs(part:GetChildren()) do
        if child:IsA('Texture') then
            child.Parent = matFolderPartition
        end
    end
end


function poolService.AddTexturesToPart(part : Part, matCode : number)
    assert(typeof(part) == 'Instance' and part:IsA('Part'), '[[Voxaria]][PoolService][.AddTexturesToPart] Argument #1 must be a Part Instance.')
    assert(typeof(matCode) == 'number', '[[Voxaria]][PoolService][.AddTexturesToPart] Argument #2 must be a number.')

    local matName : string = assetManager.GetNameFromMaterialCode(matCode)

    local matFolder = TexturePool:FindFirstChild(matName)
    if not matFolder or #matFolder:GetChildren() == 0 then
        local textures : {Texture} = assetManager.GetTextureCopies(matCode)
        for _, texture in pairs(textures) do
            texture.Parent = part
        end
    else
        local partitionFolder : Instance = matFolder:FindFirstChildOfClass('Folder')
        debrisCollector.RemoveItem(partitionFolder)

        for _, texture in pairs(partitionFolder:GetChildren()) do
            texture.Parent = part
        end
        partitionFolder:Destroy()
    end

end

return poolService