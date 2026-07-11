local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local UIHoverZoom = require(ReplicatedStorage.Shared.UI.component.Modifier.UIHoverZoom)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Container = require(script.Parent.Container)
local ZBatch = require(script.Parent.ZBatch)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local Colors = {
	["Red"] = {
		Top = "rbxassetid://71676527786891",
		Bottom = "rbxassetid://113894773096221",
	},
	["Green"] = {
		Top = "rbxassetid://131382939529396",
		Bottom = "rbxassetid://86177213224354",
	},
}

return function(props: Type.Props & {
	OnClick: () -> (),
	Color: string,
	Label: string,
	ByPass: boolean?,
})
	local ButtonContainer = Container(props)

	local HoverContainer = Container({})

	local targetPos = Vide.source(Vector2.new(0.5, 0.40))

	local pressEffect = Vide.spring(targetPos, 0.2, 0.8)

	local pos = Vide.derive(function()
		return UDim2.fromScale(pressEffect().X, pressEffect().Y)
	end)

	local HoverEffect = UIHoverZoom({
		Intensity = Vector2.new(0.1, 0.1),
		MobileExcluded = true,
	})

	return ButtonContainer({
		HoverEffect(HoverContainer(ZBatch(1, {
			ImageLabel({
				Image = Colors[props.Color].Bottom,
			}),
			ImageButton({
				Image = Colors[props.Color].Top,
				Position = pos,
				OnLeave = function()
					targetPos(Vector2.new(0.5, 0.40))
				end,
				OnBegan = function()
					targetPos(Vector2.new(0.5, 0.45))
				end,
				OnClick = function()
					task.delay(0.05, function()
						targetPos(Vector2.new(0.5, 0.40))
						task.wait(0.05)
						props.OnClick()
					end)
				end,
				Size = UDim2.fromScale(0.95, 0.9),
				ByPass = props.ByPass or false,
			}),
			TextLabel({
				Position = pos,
				Text = props.Label,
				Size = UDim2.fromScale(1, 0.7),
			}),
		}))),
	})
end
