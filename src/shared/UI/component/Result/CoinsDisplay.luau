local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local CurrencyDisplay = require(ReplicatedStorage.Shared.UI.component.Base.CurrencyDisplay)

local BOUNCE_INTENSITY = 0.9

return function(props: {
	Coins: Vide.Source<number>,
})
	local smoothDigit = Vide.spring(props.Coins, 0.8, 0.9)
	local bounce, bounceControls = Vide.spring(Vide.source(0), 0.4, 0.8)

	local previousCoins = props.Coins()
	local negative = false

	Vide.effect(function()
		negative = previousCoins > props.Coins()

		previousCoins = props.Coins()

		bounceControls({
			impulse = BOUNCE_INTENSITY,
		})
	end)

	local Display = Vide.derive(function()
		--Todo: fait les nombres abrégés (1.2K, 1.5M, etc)
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

	local BounceSize = function(origin: UDim2)
		return Vide.derive(function()
			return UDim2.fromScale(origin.X.Scale + bounce(), origin.Y.Scale + bounce())
		end)
	end

	return CurrencyDisplay({
		Position = UDim2.fromScale(0.01, 0.5),
		Size = BounceSize(UDim2.fromScale(1, 0.12)),
		Currency = Display,
		CurrencyIcon = ImageId.Coin.Id,
		AnchorPoint = Vector2.new(0, 0.5),
		ImageRatio = 0.943,
		TextSize = UDim2.fromScale(0.6, 1),
	})
end
