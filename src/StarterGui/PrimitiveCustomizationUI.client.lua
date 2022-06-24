local modules = require(game:GetService("ReplicatedStorage")["VoxelSea 2.0"].Modules.ModuleIndex)
local state = require(modules.PrimitiveBlockState)

local TweenService = game:GetService("TweenService")

local plr = game:GetService("Players").LocalPlayer
local UI = plr.PlayerGui.PrimitiveCustomization.Frame
local DisplayPart = UI.Background.ViewportFrame.Display
local Main = UI.Background.Main
local Button = plr.PlayerGui.Misc.Frame.PrimitiveCustomization
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
    end
    deb = false
end)


