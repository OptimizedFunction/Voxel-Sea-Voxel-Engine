local module = {}
module._Color = Color3.new(1,1,1)
module._Material = Enum.Material.SmoothPlastic
module._Transparency = 0
module._Reflectance = 0


function module.GetColor3() : Color3
    return module._Color
end

function module.SetColor3(newColor3 : Color3?)
    assert(typeof(newColor3) == "Color3", "[[Voxel Sea]][PrimitiveBlockTable.SetColor3] Argument #1 must be of type Color3 but is of type: "..typeof(newColor3))
    module._Color = newColor3
end

function module.GetRobloxMaterial() : Enum.Material
    return module._Material
end

function module.SetRobloxMaterial(newMaterial : Enum.Material)
    assert(typeof(newMaterial) == "EnumItem", "[[Voxel Sea]][PrimitiveBlockTable.SetRobloxMaterial] Argument #1 must be of type EnumItem (Enum.Material) but is of type: "..typeof(newMaterial))
    module._Material = newMaterial
end

function module.GetTransparency() : number
    return module._Transparency
end

function module.SetTransparency(newTransparency : number)
    assert(typeof(newTransparency) == "number", "[[Voxel Sea]][PrimitiveBlockTable.SetTransparency] Argument #1 must be of type number but is of type: "..typeof(newTransparency))
    module._Transparency = newTransparency
end

function module.GetReflectance() : number
    return module._Reflectance
end

function module.SetReflectance(newReflectance : number)
    assert(typeof(newReflectance) == "number", "[[Voxel Sea]][PrimitiveBlockTable.SetColor3] Argument #1 must be of type number but is of type: "..typeof(newReflectance))
    module._Reflectance = newReflectance
end

return module