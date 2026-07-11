-- ╔══════════════════════╗
-- ║  Modules & Services  ║
-- ╚══════════════════════╝
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationId = require(ReplicatedStorage.Shared.Asset.AnimationId)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local Rarity = require(ReplicatedStorage.Shared.Enums.Rarity)

local ModelList: { [string]: Tool } = ReplicatedStorage:WaitForChild("Weapon")

if RunService:IsClient() then
	ContentProvider:PreloadAsync(ReplicatedStorage.Animation:GetChildren())
end

-- ╔════════╗
-- ║  Info  ║
-- ╚════════╝
export type WeaponInfo = {
	Name: string,
	Damage: number,
	Duration: number,
	CoolDown: number,
	range: number,
	radius: number,
	Weight: number,
	Rarity: string,
}

export type MinData = {
	Id: string,
	Extra: { [string]: any },
}

export type WeaponData = {
	{
		Extra: { [string]: any }?,
		Count: number,
	}
}

export type EquipData = {
	Id: string,
	Index: number,
}

local weaponInfo: { [string]: WeaponInfo } = {
	["WoodenSword"] = {
		Name = "Wooden Sword",
		Damage = 5,
		Duration = 0.5,
		CoolDown = 0.05,
		range = 6,
		radius = 180,
		Weight = 10e6,
		Rarity = Rarity.Uncommon,
	},
	["WoodenBat"] = {
		Name = "Wooden Bat",
		Damage = 8,
		Duration = 0.6,
		CoolDown = 0.05,
		range = 7,
		radius = 160,
		Weight = 10e5,
		Rarity = Rarity.Rare,
	},
}

local weaponAnimation: { [string]: { Animation } } = {
	["WoodenSword"] = { AnimationId.BasicAttack.Id, AnimationId.BasicAttack2.Id },
	["WoodenBat"] = { AnimationId.BasicAttack.Id, AnimationId.BasicAttack2.Id },
}

-- ╔═════════════╗
-- ║  MetaModel  ║
-- ╚═════════════╝
local Weapon = {}
Weapon.__index = Weapon

function Weapon:GetImage()
	return ImageId[self.Id]
end

function Weapon:GetTool(): Tool
	assert(ModelList[self.Id], "The weapon Tool was not found !")
	return ModelList[self.Id]:Clone()
end

function Weapon:GetAnimation(): { Animation }
	return weaponAnimation[self.Id]
end

function Weapon:GetNextAnimationIndex(currentIndex: number): number
	if currentIndex == #self:GetAnimation() then
		return 1
	else
		return currentIndex + 1
	end
end

function Weapon.Data(Id: string, Extra: { [string]: any }?): MinData
	return {
		Id = Id,
		Extra = Extra or {}, -- right now extraData is impossible
	}
end

function Weapon.NewFromData(data: MinData): WeaponMeta
	assert(weaponInfo[data.Id], "The weapon id was not found in the list of weapon")
	local clone = table.clone(weaponInfo[data.Id])
	clone.Id = data.Id
	--TODO: unpack the extraData when we will have some

	setmetatable(clone, Weapon)
	return clone
end

function Weapon.New(id: string): WeaponInfo & { Id: string } & typeof(Weapon)
	assert(weaponInfo[id], `The weapon id "{id}" was not found in the list of weapon`)
	local clone = table.clone(weaponInfo[id])
	clone.Id = id

	setmetatable(clone, Weapon)
	return clone
end

Weapon.TotalWeight = 0

for _, info in weaponInfo do
	Weapon.TotalWeight += info.Weight
end

export type WeaponMeta = typeof(Weapon) & { Id: string } & WeaponInfo

return Weapon
