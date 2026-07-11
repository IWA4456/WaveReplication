local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UIHoverZoom = require(ReplicatedStorage.Shared.UI.component.Modifier.UIHoverZoom)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local RATIO_SIZE = 0.92

return function(props: {
	OnClick: () -> (),
})
	local DisplayContainer = Container({
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	})

	local Ratio = UISizeRatio({
		Ratio = RATIO_SIZE,
	})
	local HoverEffect = UIHoverZoom({
		Intensity = Vector2.new(0.1, 0.1),
	})

	return HoverEffect(DisplayContainer({
		Ratio(ImageButton({
			Image = ImageId.UpgradeArrow.Id,
			OnClick = props.OnClick,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.9),
		})),
	}))
end
