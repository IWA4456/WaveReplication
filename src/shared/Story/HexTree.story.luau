local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local HexMaker = require(ReplicatedStorage.Shared.HexTree.HexComponent.HexMaker)
local HexInfo = require(ReplicatedStorage.Shared.HexTree.HexInfo.HexInfo)
local HexGUI = require(ReplicatedStorage.Shared.UI.HexUI.HexGUI)

local controls = {
	ShowSource = false,
}

return {
	vide = Vide,
	controls = controls,
	story = function(props)
		local GUI: ScreenGui = Vide.create("ScreenGui")({})

		HexMaker:InitHexTree(HexInfo, props.controls.ShowSource, GUI)

		return GUI
	end,
}
