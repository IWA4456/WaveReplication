local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local Drift = require(ReplicatedStorage.Shared.Drift.Drift)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local CurrencyDisplay = require(ReplicatedStorage.Shared.UI.component.Base.CurrencyDisplay)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
return function(props: Type.Props & {
	Coins: Vide.Source<number>,
})
	local smoothDigit = Drift.Tween(props.Coins, 0.6, Drift.Easing.quadOut)

	local negative = false

	local previousCoins = props.Coins()

	Vide.effect(function()
		negative = previousCoins > props.Coins()

		previousCoins = props.Coins()
	end)

	local Display = Vide.derive(function()
		local unsigned = math.max(0, smoothDigit())

		local maxDigit
		local currentCoins = Vide.untrack(props.Coins)

		if negative then
			maxDigit = math.max(unsigned, currentCoins)
		else
			maxDigit = math.min(unsigned, currentCoins)
		end

		return math.round(maxDigit)
	end)

	local propsContainer = Container(props)
	return propsContainer({
		CurrencyDisplay({
			Currency = Display,
			Alignement = Enum.HorizontalAlignment.Center,
			CurrencyIcon = ImageId.Coin.Id,
			ImageRatio = 0.943,
		}),
	})
end
