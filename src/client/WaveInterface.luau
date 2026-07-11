local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blink = require(script.Parent.Blink)
local ClientFlow = require(script.Parent.StateFlow.ClientFlow)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Vide = require(ReplicatedStorage.Packages.Vide)
local WaveState = require(ReplicatedStorage.Shared.Enums.WaveState)
local CorePanel = require(ReplicatedStorage.Shared.UI.CorePanel.CorePanel)
local UseAtom = require(ReplicatedStorage.Shared.Utils.UseAtom)
local plr = Players.LocalPlayer

local WaveInterface = {}

function WaveInterface:Init()
	return self:Build() :: WaveInterface
end

function WaveInterface.Build(self: WaveInterface)
	self.WaveState = ClientFlow:GetAsync("WaveState")

	self.WaveRequest = Blink.WaveRequest

	local NotInWave = Vide.source(true)
	local selfShow = Vide.source(NotInWave())

	Charm.effect(function()
		NotInWave(self.WaveState() == WaveState.None)
		print(NotInWave())
		if NotInWave() then
			selfShow(NotInWave())
		end
	end)

	local radius = Charm.atom(8)

	Vide.mount(function()
		return Vide.show(selfShow, function()
			return CorePanel({
				CoreModel = Vide.source(workspace.TargetModel),
				Radius = UseAtom(radius),
				OnClick = function()
					self.WaveRequest.Fire()
				end,
				OpenSignal = NotInWave,
				SelfShow = selfShow,
			})
		end)
	end, plr.PlayerGui)

	return self
end

export type WaveInterface = typeof(WaveInterface) & {
	WaveState: Charm.Atom<number>,
	WaveRequest: typeof(Blink.WaveRequest),
}
return WaveInterface:Init() :: WaveInterface
