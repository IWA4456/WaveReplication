local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props)
	local titleContainer = Container(FastProps({
		Props = props,
		Default = props,
	}))

	local ratio = UISizeRatio({
		Ratio = ImageId.SwordTitle.Ratio,
	})

	return titleContainer({
		ratio(ImageLabel({
			Image = ImageId.SwordTitle.Id,
		})),
	})
end
