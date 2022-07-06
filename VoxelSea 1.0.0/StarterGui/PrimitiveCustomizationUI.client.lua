local modules = require(game:GetService("ReplicatedStorage")["VoxelSea 2.0"].Modules.ModuleIndex)
local state = require(modules.PrimitiveBlockState)

local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")

local plr = game:GetService("Players").LocalPlayer
local UI = plr.PlayerGui.PrimitiveCustomization.Frame
local DisplayPart = UI.Background.ViewportFrame.Display
local Main = UI.Background.Main
local Button = plr.PlayerGui.Misc.Frame.PrimitiveCustomization
local MatButton = Main.Material
local PropButton = Main.Properties
local ColorShowerFrame = Main.PropertiesFrame.Color.Bottom.ColorPickerFrame.ColorShower
local TransparencyFrame = Main.PropertiesFrame:FindFirstChild("Transparency")
local ReflectanceFrame = Main.PropertiesFrame:FindFirstChild("Reflectance")

ColorShowerFrame:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
    state.SetColor3(ColorShowerFrame.BackgroundColor3)
    DisplayPart.Color = ColorShowerFrame.BackgroundColor3
end)

TransparencyFrame.Increment.MouseButton1Click:Connect(function()
    local transparency = state.GetTransparency()
    transparency += 0.1
    transparency = math.clamp(transparency, 0, 1)
    transparency = math.round(transparency*10)/10
    state.SetTransparency(transparency)
    DisplayPart.Transparency = transparency
    TransparencyFrame.ValueLabel.Text = transparency
end)

TransparencyFrame.Decrement.MouseButton1Click:Connect(function()
    local transparency = state.GetTransparency()
    transparency -= 0.1
    transparency = math.clamp(transparency, 0, 1)
    transparency = math.round(transparency*10)/10
    state.SetTransparency(transparency)
    DisplayPart.Transparency = transparency
    TransparencyFrame.ValueLabel.Text = transparency
end)

ReflectanceFrame.Increment.MouseButton1Click:Connect(function()
    local reflectance = state.GetReflectance()
    reflectance += 0.1
    reflectance = math.clamp(reflectance, 0, 1)
    reflectance = math.round(reflectance*10)/10
    state.SetReflectance(reflectance)
    DisplayPart.Reflectance = reflectance
    ReflectanceFrame.ValueLabel.Text = reflectance
end)

ReflectanceFrame.Decrement.MouseButton1Click:Connect(function()
    local reflectance = state.GetReflectance()
    reflectance -= 0.1
    reflectance = math.clamp(reflectance, 0, 1)
    reflectance = math.round(reflectance*10)/10
    state.SetReflectance(reflectance)
    DisplayPart.Reflectance = reflectance
    ReflectanceFrame.ValueLabel.Text = reflectance
end)

MatButton.MouseButton1Click:Connect(function()
    Main.MaterialFrame.Visible = true
    Main.PropertiesFrame.Visible = false

    PropButton.BackgroundColor3 = Color3.fromRGB(150,150,150)
    MatButton.BackgroundColor3 = Color3.fromRGB(200,200,200)
end)

PropButton.MouseButton1Click:Connect(function()
    Main.MaterialFrame.Visible = false
    Main.PropertiesFrame.Visible = true

    MatButton.BackgroundColor3 = Color3.fromRGB(150,150,150)
    PropButton.BackgroundColor3 = Color3.fromRGB(200,200,200)
end)

local deb = false
Button.MouseButton1Click:Connect(function()
    if deb then return end
    deb = true
    if not UI.Visible then
        UI.Visible = true
        local tweenInfo = TweenInfo.new(1)
        local tween = TweenService:Create(UI, tweenInfo, {Position = UDim2.fromScale(0,0)})
        tween:Play()
        tween.Completed:Wait()

        CAS:BindAction("tempAction1", function() end, false, Enum.UserInputType.MouseButton1)
        CAS:BindAction("tempAction2", function() end, false, Enum.KeyCode.R)
    else
        local tweenInfo = TweenInfo.new(
            1,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        )
        local tween = TweenService:Create(UI, tweenInfo, {Position = UDim2.fromScale(1,0)})
        tween:Play()
        tween.Completed:Wait()
        UI.Visible = false

        CAS:UnbindAction("tempAction1")
        CAS:UnbindAction("tempAction2")
    end
    deb = false
end)

for _, matObj in Main.MaterialFrame.Mats:GetChildren() do
    if matObj:IsA("UIGridLayout") then continue end
    matObj.Button.MouseButton1Click:Connect(function()
        DisplayPart.Material = Enum.Material[matObj.Name]
        state.SetRobloxMaterial(Enum.Material[matObj.Name])
    end)
end


