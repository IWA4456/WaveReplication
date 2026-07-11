local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	AutomaticCanvasSize: Enum.AutomaticSize?,
	CanvasSize: UDim2?,
	ScrollBarImageColor3: Color3?,
	ScrollBarImageTransparency: number?,
	ScrollingDirection: Enum.ScrollingDirection?,
	ScrollingEnabled: boolean?,
	ScrollBarThickness: number?,
	VerticalScrollBarPosition: Enum.VerticalScrollBarPosition?,
})
	local defaultProps = {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = props.BackgroundColor3 and (props.BackgroundTransparency or 0) or 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(255, 255, 255),
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		ZIndex = 1,
		Active = false,
		Visible = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0.5),
		ScrollBarImageColor3 = Color3.fromHex("#ffffff"),
		ScrollBarImageTransparency = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = true,
		ScrollBarThickness = 10,
		VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
	}

	return Vide.create("ScrollingFrame")(FastProps({
		Props = props,
		Default = defaultProps,
		DefaultModifier = {
			UIListLayout({
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			})({}),
		},
	}))
end
