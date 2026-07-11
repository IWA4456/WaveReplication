local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local HexType = require(ReplicatedStorage.Shared.HexTree.HexType)

local SIDE = {
	TOP = "Top",
	TOP_RIGHT = "TopRight",
	TOP_LEFT = "TopLeft",
	BOTTOM = "Bottom",
	BOTTOM_RIGHT = "BottomRight",
	BOTTOM_LEFT = "BottomLeft",
}

local HexInfo: HexType.HexIdList = {
	["Center"] = {
		HexId = "Center",
		NextCells = { [SIDE.BOTTOM] = "AutoAttack1", [SIDE.TOP_LEFT] = "WeaponInventory" },
		Cost = 0,
		Color = "Orange",
		ImageId = ImageId.UpgradeArrow,
		Label = "Center",
		Description = "Welcome to the Upgrade Tree !",
	},
	["AutoAttack1"] = {
		HexId = "AutoAttack1",
		NextCells = { [SIDE.BOTTOM_RIGHT] = "SpeedStreak1" },
		Cost = 50,
		Color = "Orange",
		ImageId = { ImageId.RedoArrow, { Id = ImageId.Sword.Id, Ratio = 1, Size = UDim2.fromScale(0.45, 0.45) } },
		Label = "Auto-Attack I",
		Description = "You can activate auto attack !",
	},
	["SpeedStreak1"] = {
		HexId = "SpeedStreak1",
		NextCells = {},
		Cost = 500,
		Color = "Orange",
		ImageId = {
			{ Id = ImageId.Sword.Id, Ratio = 1, Size = UDim2.fromScale(0.5, 0.5) },
			{
				Id = ImageId.Flame.Id,
				Ratio = ImageId.Flame.Ratio,
				Size = UDim2.fromScale(0.2, 0.2),
				Position = UDim2.fromScale(0.35, 0.25),
			},
		},
		Label = "Streaks I",
		Description = "12% attack speed after a 5-hit streak",
	},
	["WeaponInventory"] = {
		HexId = "WeaponInventory",
		NextCells = { [SIDE.TOP] = "WeaponRolls" },
		Cost = 50,
		Color = "Orange",
		ImageId = {
			Id = ImageId.BackPack.Id,
			Ratio = ImageId.BackPack.Ratio,
			Size = UDim2.fromScale(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.4),
		},
		Label = "Inventory",
		Description = "Unlock the Weapon Inventory",
	},
	["WeaponRolls"] = {
		HexId = "WeaponRolls",
		NextCells = {},
		Cost = 50,
		Color = "Orange",
		ImageId = {
			{
				Id = ImageId.Dice.Id,
				Ratio = ImageId.Dice.Ratio,
				Size = UDim2.fromScale(0.45, 0.45),
				Position = UDim2.fromScale(0.46, 0.35),
			},
			{
				Id = ImageId.Sword.Id,
				Ratio = 1,
				Size = UDim2.fromScale(0.3, 0.3),
				Position = UDim2.fromScale(0.66, 0.48),
			},
		},
		Label = "Roll Weapon",
		Description = "Unlock the ability to get better Weapons with your luck",
	},
}

local function addPrevious(HexIdList: HexType.HexIdList, hexId: HexType.HexId, previousHexId: HexType.HexId?)
	local hexInfo = HexIdList[hexId]
	hexInfo.PreviousCell = previousHexId or "None"

	for _, currentHexId in pairs(hexInfo.NextCells) do
		addPrevious(HexIdList, currentHexId, hexId)
	end
end

addPrevious(HexInfo, "Center")

return HexInfo :: HexType.HexInfo
