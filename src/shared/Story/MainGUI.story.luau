local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Vide = require(ReplicatedStorage.Packages.Vide)
local ui_labs = require(ReplicatedStorage.Packages["ui-labs"])
local HexMaker = require(ReplicatedStorage.Shared.HexTree.HexComponent.HexMaker)
local HexInfo = require(ReplicatedStorage.Shared.HexTree.HexInfo.HexInfo)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local BackpackButton = require(ReplicatedStorage.Shared.UI.Inventory.BackpackButton)
local InventoryMenu = require(ReplicatedStorage.Shared.UI.Inventory.InventoryMenu)
local AttackDisplay = require(ReplicatedStorage.Shared.UI.component.Result.AttackDisplay)
local CoinsDisplay = require(ReplicatedStorage.Shared.UI.component.Result.CoinsDisplay)
local HexDisplay = require(ReplicatedStorage.Shared.UI.component.Result.HexDisplay)
local MainGUI = require(ReplicatedStorage.Shared.UI.component.Saddle.MainGUI)

local slider = ui_labs.Slider

local controls = {
	Coins = 1000,
	AttackMode = false,
	AttackState = 0,
	SizeX = slider(1, -0.5, 1.5, 0.0025),
	SizeY = slider(1, -0.5, 1.5, 0.0025),
	PositionX = slider(1, -0.5, 1.5, 0.0025),
	PositionY = slider(1, -0.5, 1.5, 0.0025),
	EquippedId = "1",
}

type props = {
	controls: typeof(controls),
}
return {
	vide = Vide,
	controls = controls,
	story = function(props: props)
		local sizeTest = Vide.derive(function()
			local x = props.controls.SizeX()
			local y = props.controls.SizeY()

			return UDim2.fromScale(x, y)
		end)

		local positionTest = Vide.derive(function()
			local x = props.controls.PositionX()
			local y = props.controls.PositionY()

			return UDim2.fromScale(x, y)
		end)

		local showHex = Vide.source(false)

		local hexOwned = {}

		for HexId, _ in HexInfo do
			table.insert(hexOwned, HexId)
		end

		local hexCharm = true and Charm.atom(hexOwned) or Charm.atom({})

		HexMaker:InitHexTree(HexInfo, showHex, MainGUI.GUI, hexCharm, props.controls.Coins)

		MainGUI:AddHider(showHex)

		MainGUI:AddComponent(function(): GuiObject
			return CoinsDisplay({
				Coins = props.controls.Coins,
			})
		end, "Left")

		MainGUI:AddComponent(function(): GuiObject
			return HexDisplay({
				OnClick = function()
					showHex(true)
				end,
			})
		end, "BottomCenter")

		MainGUI:AddComponent(function(): GuiObject
			return AttackDisplay({
				OnClick = function()
					props.controls.AttackMode(not props.controls.AttackMode())
				end,
				Enabled = props.controls.AttackMode,
				AttackState = props.controls.AttackState,
				ActiveStreak = Vide.source(true),
				Streak = Vide.source(0),
			})
		end, "BottomLeft")

		local Unlocked = Vide.source(true)
		local ShowInventory = Vide.source(true)

		MainGUI:AddComponent(function()
			return Vide.show(Unlocked, function()
				return BackpackButton({
					OnClick = function()
						ShowInventory(not ShowInventory())
					end,
				})
			end)
		end, "BottomRight")

		local initTable = {}

		for i = 1, 20 do
			local key = tostring(i)
			initTable[key] = Weapon.New("WoodenSword"):Data(key)
		end
		local mockInventory = Vide.source(initTable)

		MainGUI:AddMenu(function(): GuiObject
			return InventoryMenu({
				ShowSelf = ShowInventory,
				Inventory = mockInventory,
				EquippedId = props.controls.EquippedId,
				EquipEvent = function(key)
					props.controls.EquippedId(key)
				end,
			})
		end, ShowInventory)

		return MainGUI.GUI
	end,
}
