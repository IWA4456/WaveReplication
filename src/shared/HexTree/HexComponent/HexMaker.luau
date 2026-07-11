local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Vide = require(ReplicatedStorage.Packages.Vide)
local HexType = require(ReplicatedStorage.Shared.HexTree.HexType)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)
local HexCell = require(ReplicatedStorage.Shared.UI.HexUI.HexCell)
local HexContainer = require(ReplicatedStorage.Shared.UI.HexUI.HexContainer)
local HexGUI = require(ReplicatedStorage.Shared.UI.HexUI.HexGUI)

local SIDE_POS: { [HexType.HexSide]: Vector2 } = {
	["Top"] = Vector2.new(0, -1 / 1.06),
	["TopRight"] = Vector2.new(0.78, -1 / 2.17),
	["TopLeft"] = Vector2.new(-0.78, -1 / 2.17),
	["Bottom"] = Vector2.new(0, 1 / 1.08),
	["BottomRight"] = Vector2.new(0.78, 1 / 2.17),
	["BottomLeft"] = Vector2.new(-0.78, 1 / 2.17),
}

local HexMaker = {}

function HexMaker.InitHexTree(
	self: HexMaker,
	HexInfo: HexType.HexInfo,
	showSource: Vide.Source<boolean>,
	GUI: ScreenGui,
	HexOwned: Charm.Atom<HexType.HexData>,
	Coins: Vide.Source<number>
)
	self.HexInfo = HexInfo
	self.ShowSource = showSource
	self.ShowHex = Vide.source(false)

	if RunService:IsRunning() then
		self.HexPurchase = Jolt.Client("HexPurchase")
	end

	local HexContainerObject, HexContainerScope = HexContainer()
	local HexGUIObject, GUIScope = HexGUI({
		Leave = function()
			self.ShowSource(false)
		end,
		Coins = Coins,
	})

	self.HexContainer = HexContainerObject
	self.HexGUI = HexGUIObject

	Vide.mount(function()
		return Vide.show(self.ShowHex, function()
			GUIScope()
			return self.HexGUI
		end)
	end, GUI)

	Vide.mount(function()
		return Vide.show(self.ShowHex, function()
			HexContainerScope()
			return self.HexContainer
		end)
	end, self.HexGUI)

	self:InitHexOwned(HexOwned)

	self:InitHexCell()

	return self.HexContainer
end

function HexMaker.InitHexOwned(self: HexMaker, HexOwned: Charm.Atom<HexType.HexData>)
	self.HexOwned = {}
	for _, HexId in HexOwned() do
		self.HexOwned[HexId] = Vide.source(true)
	end
	for HexId, _ in self.HexInfo do
		if not self.HexOwned[HexId] then
			self.HexOwned[HexId] = Vide.source(false)
		end
	end

	Charm.observe(HexOwned, function(value, _): (() -> ())?
		self.HexOwned[value](true)
		return nil
	end)
end

function HexMaker.InitHexCell(self: HexMaker)
	Vide.root(function()
		Vide.effect(function()
			if self.ShowSource() then
				self.ShowHex(true)
			else
				task.delay(0.13, function()
					self.ShowHex(false)
				end)
			end
		end)
	end)

	self:buildHexCell("Center", Vector2.new(0.5, 0.5), self.ShowHex, Vide.source(true))
end

function HexMaker.buildHexCell(
	self: HexMaker,
	HexId: HexType.HexId,
	Position: Vector2,
	Show: Vide.Source<boolean>,
	PreviousOwned: Vide.Source<boolean>
)
	local HexInfo = self.HexInfo[HexId]

	local showNext = Vide.source(false)
	local owned = self.HexOwned[HexId]

	local function onClick()
		if owned() or not PreviousOwned() or not RunService:IsRunning() then
			return
		end
		self.HexPurchase:Fire(HexId)
	end

	Vide.mount(function()
		return Vide.show(Show, function() --Todo
			return HexCell({
				Color = HexInfo.Color,
				ImageId = HexInfo.ImageId,
				Cost = HexInfo.Cost,
				Position = Position,
				ShowSelf = Show,
				ShowNext = showNext,
				Exit = self.ShowSource,
				Owned = owned,
				PreviousOwned = PreviousOwned,
				OnClick = onClick,
				Label = HexInfo.Label,
				Description = HexInfo.Description,
			})
		end)
	end, self.HexContainer)

	for side, nextHexId in pairs(HexInfo.NextCells) do
		local nextPos = Position + 0.2 * SIDE_POS[side]
		self:buildHexCell(nextHexId, nextPos, showNext, owned)
	end
end

type HexMaker = typeof(HexMaker) & {
	HexInfo: HexType.HexInfo,
	ShowSource: Vide.Source<boolean>,
	ShowHex: Vide.Source<boolean>,
	HexOwned: { [HexType.HexId]: Vide.Source<boolean> },
	HexGUI: Frame,
	HexContainer: Frame,
	HexPurchase: Jolt.Client,
}

return HexMaker :: HexMaker
