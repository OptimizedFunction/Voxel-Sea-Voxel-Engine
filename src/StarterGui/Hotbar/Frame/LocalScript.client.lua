--!nocheck
local buttons = {
	
	script.Parent.Grass,
	script.Parent.Dirt,
	script.Parent.Stone
	
}

function updateMat(action, inputState, inputObj)
	if inputState == Enum.UserInputState.End then return end
	
	local i = table.find(buttons, script.Parent[action])
	
	local current_mat : IntValue = script.Parent.Parent.CurrentMat
	
	if buttons[current_mat.Value] then
		buttons[current_mat.Value].BorderColor3 = Color3.fromRGB(156,156,156)
	end
	
	current_mat.Value = i
	buttons[i].BorderColor3 = Color3.fromRGB(0,0,255)

end


for i = 1, #buttons do
	buttons[i].MouseButton1Click:Connect(function()
		local current_mat : IntValue = script.Parent.Parent.CurrentMat
		if buttons[current_mat.Value] then
			buttons[current_mat.Value].BorderColor3 = Color3.fromRGB(156,156,156)
		end
		current_mat.Value = i
		buttons[i].BorderColor3 = Color3.fromRGB(0,0,255)
	end)
end


local CAS : ContextActionService = game:GetService('ContextActionService')
CAS:BindAction('Grass', updateMat, false, Enum.KeyCode.One)
CAS:BindAction('Dirt', updateMat, false, Enum.KeyCode.Two)
CAS:BindAction('Stone', updateMat, false, Enum.KeyCode.Three)


