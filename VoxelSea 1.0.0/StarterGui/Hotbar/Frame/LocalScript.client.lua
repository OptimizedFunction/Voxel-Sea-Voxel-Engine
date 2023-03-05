--!nocheck
local buttons = {

	script.Parent.Grass,
	script.Parent.Dirt,
	script.Parent.Stone,
	script.Parent.Primitive

}

function updateMat(action, inputState)
	if inputState == Enum.UserInputState.End then return end

	local i = table.find(buttons, script.Parent[action])

	local current_mat : IntValue = script.Parent.Parent.CurrentMat

	if buttons[current_mat.Value] then
		buttons[current_mat.Value].UIStroke.Color = Color3.fromRGB(0,0,0)
		buttons[current_mat.Value].UIStroke.Thickness = 1
	end

	current_mat.Value = i
	buttons[i].UIStroke.Thickness = 2.5

end


for i = 1, #buttons do
	buttons[i].MouseButton1Click:Connect(function()
		local current_mat : IntValue = script.Parent.Parent.CurrentMat
		if buttons[current_mat.Value] then
			buttons[current_mat.Value].UIStroke.Color = Color3.fromRGB(0,0,0)
			buttons[current_mat.Value].UIStroke.Thickness = 1
		end
		current_mat.Value = i
		buttons[i].UIStroke.Thickness = 2.5
	end)
end


local CAS : ContextActionService = game:GetService("ContextActionService")
CAS:BindAction("Grass", updateMat, false, Enum.KeyCode.One)
CAS:BindAction("Dirt", updateMat, false, Enum.KeyCode.Two)
CAS:BindAction("Stone", updateMat, false, Enum.KeyCode.Three)
CAS:BindAction("Primitive", updateMat, false, Enum.KeyCode.Four)


