local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer 
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = ReplicatedFirst:FindFirstChild("LoadingScreen")
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
-- screenGui.Enabled = false

local loadingRing = Instance.new("ImageLabel")
loadingRing.Size = UDim2.new(1.3, 0, 1.3, 0)
loadingRing.SizeConstraint = Enum.SizeConstraint.RelativeXX
loadingRing.BackgroundTransparency = 1
loadingRing.Image = "rbxassetid://4965945816"
loadingRing.AnchorPoint = Vector2.new(0.5, 0.5)
loadingRing.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingRing.ZIndex = 1001
screenGui.UIAspectRatioConstraint.Parent = loadingRing
loadingRing.Parent = screenGui.Frame.TextLabel

local loaded = false

local init_time = os.clock()

-- Remove the default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

coroutine.wrap(function()
	while not loaded do
		loadingRing.Rotation += 2
		game:GetService('RunService').RenderStepped:Wait()
	end
end)()

if not game:IsLoaded() then
	game.Loaded:Wait()
	script.Parent.LoadedEvent.Event:Wait()
	game:GetService('ContentProvider'):PreloadAsync({game:GetService('ReplicatedStorage')["VoxelSea 2.0"].Modules.AssetManager.Textures})
end

screenGui.Frame.TextLabel.Text = 'Loading Complete!'

for _ = 1,100 do
	loadingRing.ImageTransparency += 1/100
	game:GetService('RunService').RenderStepped:Wait()
end
loaded = true
loadingRing:Destroy()

local plr = game:GetService('Players').LocalPlayer
local char = plr.Character
if char then char:MoveTo(Vector3.new(char:GetPrimaryPartCFrame().Position.X, 120, char:GetPrimaryPartCFrame().Position.Z)) end

local baseplate = workspace:WaitForChild('Baseplate')
baseplate:Destroy()

screenGui.Frame:TweenPosition(screenGui.Frame.Position + UDim2.new(0,0,-1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.6)
task.wait(2)
screenGui:Destroy()

print('Loading took: '..tostring(os.clock() - init_time))