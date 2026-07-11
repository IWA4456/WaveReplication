local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HexMaker = require(script.Parent.HexMaker)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Vide = require(ReplicatedStorage.Packages.Vide)
local HexType = require(ReplicatedStorage.Shared.HexTree.HexType)
local HexClient = {}

function HexClient.Init(
	self: HexClient,
	HexInfo: HexType.HexInfo,
	GUI: ScreenGui,
	HexData: Charm.Atom<HexType.HexData>,
	Coins: Charm.Atom<number>
): HexClient
	self.HexInfo = HexInfo
	self.GUI = GUI
	self.Coins = Coins

	self:BuildAdvancedHexOwned(HexData)

	self.ShowHexUI = Vide.source(false)
	self:BuildHexUI(HexData)

	return self
end

function HexClient.BuildHexUI(self: HexClient, HexData: Charm.Atom<HexType.HexData>)
	--Todo
	local coinsSource = Vide.source(self.Coins())

	Charm.effect(function()
		coinsSource(self.Coins())
	end)

	HexMaker:InitHexTree(self.HexInfo, self.ShowHexUI, self.GUI, HexData, coinsSource)
end

function HexClient.BuildAdvancedHexOwned(self: HexClient, HexData: Charm.Atom<HexType.HexData>)
	local initHex = {}
	for _, HexId in HexData() do
		initHex[HexId] = true
	end

	for HexId, _ in self.HexInfo do
		if not initHex[HexId] then
			initHex[HexId] = false
		end
	end

	self.HexOwned = Charm.atom(initHex)

	Charm.observe(HexData, function(value, _): (() -> ())?
		local hexClone = table.clone(self.HexOwned())

		hexClone[value] = true

		self.HexOwned(hexClone)
		return nil
	end)
end

export type HexClient = typeof(HexClient) & {
	HexInfo: HexType.HexInfo,
	HexOwned: Charm.Atom<{ [string]: boolean }>,
	ShowHexUI: Vide.Source<boolean>,
	GUI: ScreenGui,
	Coins: Charm.Atom<number>,
} --Todo

return HexClient :: HexClient
