local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	Image: Type.value<string>,
	ImageColor3: Type.value<Color3>?,
	ImageTransparency: number?,
})
	local defaultProps = {
		BackgroundTransparency = 1,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ImageColor3 = Color3.fromHex("#ffffff"),
		Visible = true,
		ImageTransparency = 0,
		Rotation = 0,
		ZIndex = 0,
	}

	return Vide.create("ImageLabel")(FastProps({
		Props = props,
		Default = defaultProps,
		HardProps = {
			Image = props.Image,
		},
	}))
end
