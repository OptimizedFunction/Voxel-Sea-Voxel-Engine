script.Parent.MouseButton1Click:Connect(function()
	
	local plr = game:GetService('Players').LocalPlayer
	local char = plr.Character
	if char then char:MoveTo(Vector3.new(char:GetPrimaryPartCFrame().Position.X, 400, char:GetPrimaryPartCFrame().Position.Z)) end
end)