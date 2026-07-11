local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local HexType = require(ReplicatedStorage.Shared.HexTree.HexType)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)

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

export type AtomTemplate = {
	Money: Charm.Atom<number>,
	KillCount: Charm.Atom<number>,
	Weapons: Charm.Atom<{ [string]: WeaponData }>,
	EquipedWeapon: Charm.Atom<EquipData>,
	Core: Charm.Atom<string>,
	HexData: Charm.Atom<HexType.HexData>,
	AutoAttack: Charm.Atom<boolean>,
	WinRate: Charm.Atom<number>,
	NextId: Charm.Atom<number>,
}
local AtomTemplate = {}

function AtomTemplate.New(): AtomTemplate
	return {
		Money = Charm.atom(0),
		KillCount = Charm.atom(0),
		Weapons = Charm.atom({}),
		EquipedWeapon = Charm.atom({
			Id = "WoodenSword",
			Index = 1,
		}),
		Core = Charm.atom(""),
		HexData = Charm.atom({}),
		AutoAttack = Charm.atom(false),
		WinRate = Charm.atom(1),
		NextId = Charm.atom(2),
	} :: AtomTemplate
end

return AtomTemplate
