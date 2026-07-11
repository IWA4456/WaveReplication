local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local HexCell = require(ReplicatedStorage.Shared.UI.HexUI.HexCell)

local controls = {}

return {
	vide = Vide,
	controls = controls,
	story = function(props)
		return HexCell({
			Color = "Orange",
			ImageId = ImageId.Coin.Id,
			Cost = 1000,
		})
	end,
}
