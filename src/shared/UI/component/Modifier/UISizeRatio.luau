local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: {
	Ratio: Type.value<number>?,
	Type: Enum.AspectType?,
	Axis: Enum.DominantAxis?,
})
	return function(target: GuiObject)
		local ratio = Vide.create("UIAspectRatioConstraint")({
			AspectRatio = props.Ratio or 1,
			AspectType = props.Type or Enum.AspectType.ScaleWithParentSize,
			DominantAxis = props.Axis or Enum.DominantAxis.Width,
		})

		ratio.Parent = target

		return target
	end
end
