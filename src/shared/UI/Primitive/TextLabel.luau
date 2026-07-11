local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local UIStroke = require(ReplicatedStorage.Shared.UI.component.Modifier.UIStroke)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	Text: string?,
	Font: Enum.Font?,
	TextColor3: Color3?,
	TextScaled: boolean?,
	TextSize: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignement: Enum.TextYAlignment?,
	TextWrapped: boolean?,
	TextTransparency: number?,
})
	local defaultProps = {
		Text = "None",
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.fromHex("#ffffff"),
		TextScaled = if props.TextSize then false else props.TextScaled or true,
		TextSize = 14,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = true,
		ZIndex = 0,
		TextWrapped = true,
		Rotation = 0,
		TextTransparency = props.TextTransparency or 0,
	}

	return Vide.create("TextLabel")(FastProps({
		Props = props,
		Default = defaultProps,
		DefaultModifier = {
			UIStroke({}),
		},
	}))
end
