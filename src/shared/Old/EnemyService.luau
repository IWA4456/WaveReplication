--Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Charm_Sync = require(ReplicatedStorage.Packages["Charm-Sync"])
local Enemy = require(ReplicatedStorage.Shared.Info.Enemy)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)

--Events
local SyncEnemyState = Jolt.Server("SyncEnemyState")
local requestEnemyState = Jolt.Server("RequestEnemyState")

--types
type StatePos = {
	IdWave: string,
	Pos: Vector3,
	Velocity: Vector3,
}
type WaveData = {
	[string]: StatePos,
}

type WaveInit = {
	[string]: InitInfo,
}

type InitInfo = {
	IdInfo: string,
	IdWave: string,
	TimeSpawn: number,
}

-- Tables
--right now this only handle the enemy health, but it can be used for more in the future
local EnemyAtom: { [Player]: Charm.Atom<{ [string]: number }> } = {}

local BroomerProfile: { [Player]: { () -> () } } = {}

-- ╟───────────────────╢
-- ║  Wave Management  ║
-- ╟───────────────────╢
function InitializeFromWave(plr: Player, waveInit: WaveInit)
	assert(EnemyAtom[plr], "The player does not have his atoms !")

	local enemyHealths = {}
	for key, enemy in waveInit do
		enemyHealths[key] = Enemy(enemy.IdInfo).Health
	end

	EnemyAtom[plr](enemyHealths)
end

-- ╔══════════╗
-- ║  Attack  ║
-- ╚══════════╝

local KillEnemy: (Player, { string }) -> ()

function processDeath(plr: Player, idWave: { string }, enemyHealth: { [string]: number })
	if #idWave == 0 then
		return
	end

	KillEnemy(plr, idWave)

	for _, id in idWave do
		enemyHealth[id] = nil
	end
end

function applyDamage(plr: Player, idWave: { string }, damage: number): { [string]: number }
	local enemyHealth = table.clone(EnemyAtom[plr]())

	local delta = {}
	local killed = {}
	for _, id in idWave do
		enemyHealth[id] = math.max(0, enemyHealth[id] - damage)
		delta[id] = EnemyAtom[plr]()[id] - enemyHealth[id]

		if enemyHealth[id] <= 0 then
			table.insert(killed, id)
		end
	end

	processDeath(plr, killed, enemyHealth)

	EnemyAtom[plr](enemyHealth)

	return delta
end

-- ╟─────────────────────╢
-- ║  Player Management  ║
-- ╟─────────────────────╢
function onPlayerAdded(plr: Player) -- init the charm syncer
	EnemyAtom[plr] = Charm.atom({})

	--Charm Syncer
	local syncer = Charm_Sync.server({
		atoms = {
			EnemyAtom[plr],
		},
		autoSerialize = false,
	})

	local cleaner1 = syncer:connect(function(player, ...)
		SyncEnemyState:Fire(player, ...)
	end)

	local cleaner2 = requestEnemyState:Connect(function(player: Player)
		if player ~= plr then
			return
		end
		syncer:hydrate(player)
	end)

	BroomerProfile[plr] = {
		function()
			cleaner2:Disconnect()
			cleaner1()
		end,
	}
end

function cleanPlayer(plr: Player)
	--clean broomer
	for _, broom in BroomerProfile[plr] do
		broom()
	end
	--clean Atoms and syncer
	EnemyAtom[plr] = nil
	BroomerProfile[plr] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(cleanPlayer)

-- ╔══════════════════╗
-- ║  Initialization  ║
-- ╚══════════════════╝

local function enterKillPower(callback: (Player, { string }) -> ())
	KillEnemy = callback
end

-- ★ Final Return ★ --
-- ~~~~~~~~~~~~~~~~~ --
return {
	InitializeFromWave = InitializeFromWave,
	applyDamage = applyDamage,
	enterKillPower = enterKillPower,
}
