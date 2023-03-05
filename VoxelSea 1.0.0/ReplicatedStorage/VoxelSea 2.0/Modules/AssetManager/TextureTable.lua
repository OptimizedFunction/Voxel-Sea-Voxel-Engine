local rootTexturesFolder = script.Parent:FindFirstChild("Textures")
local module = {
	{
		["Name"] = "Air";
	 	["Code"] = 0;
	 	["Textures"] = nil;
	};

	{
		["Name"] = "Grass";
	 	["Code"] = 1;
	 	["Textures"] = rootTexturesFolder.Grass;
	};

	{
        ["Name"] = "Dirt";
        ["Code"] = 2;
        ["Textures"] = rootTexturesFolder.Dirt;
	};

	{
		["Name"] = "Stone";
	 	["Code"] = 3;
	 	["Textures"] = rootTexturesFolder.Stone;
	};

    {
        ["Name"] = "Primitive";
	 	["Code"] = 4;
	 	["Textures"] = rootTexturesFolder.Primitive;
    }
}

return module