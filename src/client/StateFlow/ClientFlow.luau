local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local StateBlink = require(script.Parent.StateBlink)

local plr = Players.LocalPlayer

local ClientFlow = {}

type ClientFlow = ClientFlow_Method & {
	FlowSync: typeof(StateBlink.FlowSync),
	FlowReady: typeof(StateBlink.FlowReady),
	FlowInit: typeof(StateBlink.FlowInit),
	Atoms: { [string]: Charm.Atom<any> },
}

function ClientFlow:Init()
	return self:Build()
end

function ClientFlow.Build(self: ClientFlow)
	self.Atoms = {}

	self.FlowReady = StateBlink.FlowReady
	self.FlowSync = StateBlink.FlowSync
	self.FlowInit = StateBlink.FlowInit

	self.FlowInit.On(function(initValues: { [string]: any })
		self:OnFlowInit(initValues)
	end)

	self.FlowSync.On(function(updates)
		CharmSync.client.patch(updates)
	end)

	self.FlowReady.Fire()
	return self
end

function ClientFlow.OnFlowInit(self: ClientFlow, initValues: { Keys: { string }, Values: { [string]: any } })
	local atoms: { [string]: Charm.Atom<any> } = {}

	for _, key in initValues.Keys do
		local value = initValues.Values[key]
		local atom = Charm.atom(value)

		self.Atoms[key] = atom
		atoms[`{key}-{plr.UserId}`] = atom
	end

	CharmSync.client.addSignals(atoms)
end

function ClientFlow.GetAsync(self: ClientFlow, key: string)
	local timeRequest = time()

	while not self.Atoms[key] do
		if time() - timeRequest > 10 then
			error(`[ClientFlow]: The yield for the key "{key}" is too long !`)
		end

		task.wait()
	end

	return self.Atoms[key]
end

type ClientFlow_Method = typeof(ClientFlow)

return ClientFlow:Init() :: ClientFlow
