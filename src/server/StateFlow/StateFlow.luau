local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local StateBlink = require(script.Parent.StateBlink)
local StateFlow = {}

type PlayerFlow = {
	PendingAtoms: { [string]: Charm.Atom<any> },
	Ready: boolean,
	Building: boolean,
}

type StateFlow = StateFlow_Method & {
	FlowSync: typeof(StateBlink.FlowSync),
	FlowReady: typeof(StateBlink.FlowReady),
	FlowInit: typeof(StateBlink.FlowInit),
	PlayerFlow: { [Player]: PlayerFlow },
}

function StateFlow:Init()
	return self:Build()
end

function StateFlow.Build(self: StateFlow)
	self.PlayerFlow = {}

	self.FlowSync = StateBlink.FlowSync
	self.FlowInit = StateBlink.FlowInit
	self.FlowReady = StateBlink.FlowReady

	Players.PlayerRemoving:Connect(function(plr: Player)
		self:CleanPlr(plr)
	end)

	self.FlowReady.On(function(plr: Player)
		self:OnReady(plr)
	end)

	CharmSync.config.fixArrays = false
	CharmSync.server.connect(self.FlowSync.Fire)

	return self
end

function StateFlow.InitPlr(self: StateFlow, plr: Player)
	self.PlayerFlow[plr] = {
		PendingAtoms = {},
		Building = false,
		Ready = false,
	}
end

function StateFlow.CleanPlr(self: StateFlow, plr: Player)
	CharmSync.server.removeClient(plr)
	self.PlayerFlow[plr] = nil
end

function StateFlow.OnReady(self: StateFlow, plr: Player)
	if not self.PlayerFlow[plr] then
		self:InitPlr(plr)
	end

	local flow = self.PlayerFlow[plr]
	if flow.Ready then
		return
	end

	self:SyncAtoms(plr)

	flow.Ready = true
end

function StateFlow.Register(self: StateFlow, plr: Player, Atoms: { [string]: Charm.Atom<any> })
	if not self.PlayerFlow[plr] then
		self:InitPlr(plr)
	end

	local flow = self.PlayerFlow[plr]

	for key, atom in Atoms do
		flow.PendingAtoms[key] = atom
	end

	if not flow.Ready or flow.Building then
		return
	end

	flow.Building = true

	task.defer(function()
		self:SyncAtoms(plr)
		flow.Building = false
	end)
end

function StateFlow.SyncAtoms(self: StateFlow, plr: Player)
	local flow = self.PlayerFlow[plr]

	if not flow then
		return
	end

	local initInfo = { Keys = {}, Values = {} }
	local uniqueAtoms = {}

	for key, atom in flow.PendingAtoms do
		table.insert(initInfo.Keys, key)
		initInfo.Values[key] = atom()

		uniqueAtoms[`{key}-{plr.UserId}`] = atom
	end

	if #initInfo.Keys == 0 then
		return
	end

	self.FlowInit.Fire(plr, initInfo)

	CharmSync.server.addSignalsToClient(plr, uniqueAtoms)

	flow.PendingAtoms = {}
end

type StateFlow_Method = typeof(StateFlow)

return StateFlow:Init() :: StateFlow
