local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local HoverEffect = require(ReplicatedStorage.Shared.UI.component.Behavior.HoverEffect)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	OnClick: () -> (),
})
	local buttonContainer = Container(FastProps({
		Props = props,
		Default = props,
		HardProps = {
			AnchorPoint = Vector2.new(0, 0),
		},
	}))

	local hoverContainer = Container({})

	local ratio = UISizeRatio({
		Ratio = ImageId.ExitInventory.Ratio,
	})

	return buttonContainer({
		hoverContainer({
			ratio(ImageButton({
				Image = ImageId.ExitInventory.Id,
				OnClick = props.OnClick,
				HoverEffect({
					TargetParent = true,
				}),
			})),
		}),
	})
end
