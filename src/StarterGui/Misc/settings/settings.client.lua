--!nocheck
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local open = false

script.Parent.MouseButton1Click:Connect(function()
	local unstuck = script.Parent.Parent.unstuck
	local render_Dist_label = script.Parent.Parent.RenderDistanceLabel

	if not open then

		unstuck:TweenPosition(
			UDim2.fromScale(0.5,0.55),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true
		)
		render_Dist_label:TweenPosition(
			UDim2.fromScale(0.5,0.415),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true
		)

		open = true

		return
	end

	if open then

		unstuck:TweenPosition(
			UDim2.fromScale(0.5,-1),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true
		)

		render_Dist_label:TweenPosition(
			UDim2.fromScale(0.5,-1.135),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true
		)

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

		unstuck:TweenPosition(
			UDim2.fromScale(0.5,0.55),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			1,
			true
		)
		render_Dist_label:TweenPosition(
			UDim2.fromScale(0.5,0.415),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			1,
			true
		)

		open = true

		return
	end

	if open then

		unstuck:TweenPosition(
			UDim2.fromScale(0.5,-1),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true
		)

		render_Dist_label:TweenPosition(
			UDim2.fromScale(0.5,-1.135),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true
		)

		open = false

		return
	end
end

CAS:BindAction('Settings', handler, false, Enum.KeyCode.Tab)