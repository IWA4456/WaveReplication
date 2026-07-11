local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Container = require(script.Parent.Container)
local CurrencyDisplay = require(script.Parent.CurrencyDisplay)
local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	Price: Vide.Source<number>,
	Coins: Vide.Source<number>,
})
	local propsContainer = Container(props)

	local Color = Vide.derive(function()
		local price = props.Price()
		local coins = props.Coins()

		if coins < price then
			return Color3.new(1, 0.368627, 0.368627)
		end

		return Color3.new(1, 1, 1)
	end)

	return propsContainer({
		CurrencyDisplay({
			CurrencyIcon = ImageId.Coin.Id,
			Currency = props.Price,
			TextColor = Color,
			ImageRatio = 0.943,
			Alignement = Enum.HorizontalAlignment.Center,
			TextSize = UDim2.fromScale(0.5, 1),
		}),
	})
end
