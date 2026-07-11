local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local CurrencyDisplay = require(ReplicatedStorage.Shared.UI.component.Base.CurrencyDisplay)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local BOUNCE_INTENSITY = 4

return function(props: Type.Props & {
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

	local CoinContainer = Container({
		Size = UDim2.fromScale(0.25, 0.1),
		Position = UDim2.fromScale(0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
	})

	local propsContainer = Container(props)

	return CoinContainer({
		propsContainer({
			CurrencyDisplay({
				Position = UDim2.fromScale(0.5, 0.5),
				Size = BounceSize(UDim2.fromScale(1, 1)),
				Currency = Display,
				CurrencyIcon = ImageId.Coin.Id,
				ImageRatio = 0.943,
			}),
		}),
	})
end
