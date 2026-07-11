local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	Coins: Vide.Source<number>,
})
	local ItemContainer = Container({})

	local Ratio = UISizeRatio({
		Ratio = 0.943,
	})

	return ItemContainer(FastProps({
		Props = props,
		Default = {},
		Children = ZBatch(0, {
			Ratio(ImageLabel({
				Image = ImageId.Coin.Id,
			})),
			TextLabel({
				Text = props.Coins,
				AnchorPoint = Vector2.new(0.5, 1),
				Size = UDim2.fromScale(1, 0.4),
				Position = UDim2.fromScale(0.5, 1.1),
			}),
		}),
	}))
end
