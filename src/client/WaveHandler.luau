local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local Blink = require(script.Parent.Blink)
local EntityController = require(script.Parent.EntityController)
local ground: BasePart = workspace.Baseplate

local groundLevel = ground.Size.Y / 2 + ground.Position.Y

function receiveEnemyTracker(enemyTracker: buffer)
	local y = groundLevel
	local count = buffer.len(enemyTracker) / 5

	for i = 0, count - 1 do
		local offset = i * 5
		local idWave = tostring(buffer.readu8(enemyTracker, offset))
		local x = buffer.readi16(enemyTracker, offset + 1) / 100
		local z = buffer.readi16(enemyTracker, offset + 3) / 100

		local pos = Vector3.new(x, y, z)
		EntityController.UpdateMovement(idWave, pos)
	end
end
Blink.UnreliableSync.On(receiveEnemyTracker)

local waveState = {
	None = 0,
	Active = 1,
	Completed = 2,
}

local health = Charm.atom({})
local status = Charm.atom(waveState.None)

local plr = Players.LocalPlayer
local UserId = plr.UserId

CharmSync.client.addSignals({
	[`EntitiesHealth-{UserId}`] = health,
	[`WaveStatus-{UserId}`] = status,
})

Blink.Sync.On(function(updates)
	CharmSync.client.patch(updates)
end)

Blink.PlayerReady.Fire()

Charm.observe(health, function(item, key): ...(() -> ())
	local entityHealth = Charm.computed(function()
		if not health()[key] then
			return 0
		end

		return health()[key]
	end)
	EntityController.InitializeEnemy(key, entityHealth)
end)

return {}
