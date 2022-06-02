--!nocheck
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local open = false

script.Parent.MouseButton1Click:Connect(function()
	local unstuck = script.Parent.Parent.unstuck
	local render_Dist_label = script.Parent.Parent.RenderDistanceLabel

	if not open then
		script.Parent.Text = 'Back [Tab]'

		unstuck.Active = true
		unstuck.Visible = true

		render_Dist_label.Visible = true
		render_Dist_label.RenderDistanceInput.Active = true

		open = true

		return
	end

	if open then
		script.Parent.Text = 'Settings [Tab]'

		unstuck.Active = false
		unstuck.Visible = false

		render_Dist_label.Visible = false
		render_Dist_label.RenderDistanceInput.Active = false

		open = false

		return
	end
end)


local CAS = game:GetService('ContextActionService')

function handler(_, input_state, _)
	if input_state == Enum.UserInputState.End then return end

	local unstuck = script.Parent.Parent.unstuck
	local render_Dist_label = script.Parent.Parent.RenderDistanceLabel

	if not open then
		script.Parent.Text = 'Back [Tab]'

		unstuck.Active = true
		unstuck.Visible = true

		render_Dist_label.Visible = true
		render_Dist_label.RenderDistanceInput.Active = true

		open = true

		return
	end

	if open then
		script.Parent.Text = 'Settings [Tab]'

		unstuck.Active = false
		unstuck.Visible = false

		render_Dist_label.Visible = false
		render_Dist_label.RenderDistanceInput.Active = false

		open = false
		
		return
	end
end

CAS:BindAction('Settings', handler, false, Enum.KeyCode.Tab)