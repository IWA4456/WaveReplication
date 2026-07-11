local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local CoinsItems = require(ReplicatedStorage.Shared.UI.component.Result.CoinsItems)
local LifeBar = require(ReplicatedStorage.Shared.UI.component.Result.LifeBar)

local controls = {
	Coins = 10,
}

return {
	vide = Vide,
	controls = controls,
	story = function(props)
		return CoinsItems({
			Coins = props.controls.Coins,
		})
	end,
}
