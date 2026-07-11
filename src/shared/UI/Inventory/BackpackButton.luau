local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UIHoverZoom = require(ReplicatedStorage.Shared.UI.component.Modifier.UIHoverZoom)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	OnClick: () -> (),
})
	local PropsContainer = Container({
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(1.3, 1.3),
	})

	local DisplayContainer = Container({})

	local hoverEffect = UIHoverZoom({
		Intensity = Vector2.new(0.1, 0.1),
	})

	local ratio = UISizeRatio({
		Ratio = ImageId.BackPack.Ratio,
	})

	return PropsContainer({
		hoverEffect(DisplayContainer({
			ratio(ImageButton({
				Image = ImageId.BackPack.Id,
				OnClick = props.OnClick,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.82),
			})),
		})),
	})
end
