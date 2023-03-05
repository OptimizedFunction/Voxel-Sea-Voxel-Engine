local voxel_size = require(require(script.Parent.ModuleIndex).Configuration).GetVoxelSize()
local rootTexturesFolder = script:FindFirstChild('Textures')

local assetManager = {}

assetManager.Material_Info = {
	{
		['Name'] = 'Air';
	 	['Code'] = 0;
	 	['Textures'] = nil;
	};

	{
		['Name'] = 'Grass';
		['Code'] = 1;
		['Textures'] = rootTexturesFolder.Grass;
	};

	{
		['Name'] = 'Dirt';
		['Code'] = 2;
		['Textures'] = rootTexturesFolder.Dirt;
	};

	{
		['Name'] = 'Stone';
		['Code'] = 3;
		['Textures'] = rootTexturesFolder.Stone;
	};
}

function assetManager.GetNameFromMaterialCode(code : number) : string
	assert(typeof(code) == 'number', '[[Voxaria]][AssetManager.GetNameFromMaterialCode] Argument #1 must be a number.')

	local materialName : string
    for _, material in pairs(assetManager.Material_Info) do
        if material.Code == code then
            materialName = material.Name
        end
    end
	return materialName
end

function  assetManager.GetTextureCopies(material : number | string) : {Texture}
	assert(typeof(material) == 'number' or typeof(material) == 'string', '[[Voxaria]][AssetManager.GetNameTextureCopies] Argument #1 must be either a number or a string.')

	local materialName : string
    local textureCopies : {Texture} = {}

    if typeof(material) == 'number' then
        materialName = assetManager.GetNameFromMaterialCode(material)
	elseif typeof(material) == 'string' then
		materialName = material
	end

    for _, mat in pairs(assetManager.Material_Info) do
        if mat.Name == materialName then
            for _, texture in pairs (mat.Textures:GetChildren()) do
                local textureCopy = texture:Clone()
                textureCopy.StudsPerTileU = voxel_size
				textureCopy.StudsPerTileV = voxel_size

				table.insert(textureCopies, textureCopy)
            end
        end
    end
    return textureCopies
end

return assetManager