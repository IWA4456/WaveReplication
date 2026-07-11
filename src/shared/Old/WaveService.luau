local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotService = require(ServerScriptService.Game.PlotService.PlotService)
local EnemyService = require(script.Parent.EnemyService)
local Enemy = require(ReplicatedStorage.Shared.Info.Enemy)
local Wave = require(ReplicatedStorage.Shared.Info.Wave)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)
local ArrayUtils = require(ReplicatedStorage.Shared.Utils.ArrayUtils)

--events
local WaveSync = Jolt.Server("WaveSync")
local EnemyTracker = Jolt.Server("EnemyTracker")

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

local WaveService = {}

-- ╔═══════════════╗
-- ║  Grid System  ║
-- ╚═══════════════╝
local CELL_SIZE = 4

type Cell = { [string]: StatePos }
type SpatialGrid = { [string]: Cell }

function GetKey(position: Vector3): string
	local x = math.floor(position.X / CELL_SIZE)
	local z = math.floor(position.Z / CELL_SIZE)
	return x .. "," .. z
end

function buildGrid(enemies: WaveData): SpatialGrid
	local grid: SpatialGrid = {}

	for id, enemy: StatePos in enemies do
		local key = GetKey(enemy.Pos)
		if not grid[key] then
			grid[key] = {}
		end
		grid[key][id] = enemy
	end
	return grid
end

function getNeighbors(grid: SpatialGrid, position: Vector3): { StatePos }
	local neighbours = {}
	local cx = math.floor(position.X / CELL_SIZE)
	local cz = math.floor(position.Z / CELL_SIZE)

	for dx = -1, 1 do
		for dz = -1, 1 do
			local key = (cx + dx) .. "," .. (cz + dz)
			if grid[key] then
				for _, enemy in grid[key] do
					table.insert(neighbours, enemy)
				end
			end
		end
	end

	return neighbours
end

-- ╔═══════════════════╗
-- ║  Velocity System  ║
-- ╚═══════════════════╝
local SEPARATION_RADIUS = 3.5
local SEPARATION_STRENGTH = 1000
local CORE_STRENGTH = 10000

function GetPushFromNeighbors(enemy: StatePos, neighbors: { StatePos }, speed: number)
	local push = Vector3.zero

	for _, other in neighbors do
		if other.IdWave == enemy.IdWave then
			continue
		end

		local diff = enemy.Pos - other.Pos

		local dist = diff.Magnitude

		if dist < SEPARATION_RADIUS and dist > 0.001 then
			local strength = (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS
			push += diff.Unit * strength * SEPARATION_STRENGTH * speed
		end
	end

	return push * Vector3.new(1, 0, 1)
end

function GetPushFromCore(enemy: StatePos, corePos: Vector3, speed: number, radius: number)
	local corePos2 = Vector3.new(corePos.X, enemy.Pos.Y, corePos.Z)

	local diff = enemy.Pos - corePos2

	local dist = diff.Magnitude

	local push = Vector3.zero

	if dist < radius and dist > 0.001 then
		local strength = (radius - dist) / radius
		push += diff.Unit * strength * CORE_STRENGTH * speed
	end

	return push * Vector3.new(1, 0, 1)
end

function ApplyVelocityFromTarget(enemy: StatePos, targetPos: Vector3, dt: number, speed: number)
	targetPos = Vector3.new(targetPos.X, enemy.Pos.Y, targetPos.Z)

	local diff = (targetPos - enemy.Pos)

	if diff.Magnitude > 0.001 then
		enemy.Velocity = diff.Unit * speed
	end
end

-- ╔═════════════════╗
-- ║  Wave Building  ║
-- ╚═════════════════╝
local REVERSE = { -1, 1 }

function createArmyPos(enemyGroup: Wave.EnemyGroup): { Vector2 }
	local dimension = enemyGroup.dimension

	local evenX = dimension.X % 2 == 0

	local centerIndex: number = evenX and dimension.X / 2 or (dimension.X + 1) / 2

	local centerPos: Vector2 = nil

	if evenX then
		centerPos = Vector2.new(-enemyGroup.spreadFactor / 2, 0)
	else
		centerPos = Vector2.new(0, 0)
	end

	local tablePos = {}

	for x = 1, dimension.X do
		local diffCenter = x - centerIndex
		local xPos = centerPos.X + enemyGroup.spreadFactor * diffCenter
		for y = 1, dimension.Y do
			table.insert(tablePos, Vector2.new(xPos, enemyGroup.spreadFactor * y))
		end
	end

	return tablePos
end

function BuildWave(wave: { Wave.EnemyGroup }, plr: Player): (WaveData, WaveInit)
	local idIncr = 1
	local waveData = {}
	local waveInit = {}

	local plrCore = PlotService:GetCore(plr)
	local groundLevel = PlotService:GetGroundLevel(plr)

	for _, enemyGroup in wave do
		local xFactor = REVERSE[math.random(1, 2)]
		local yFactor = REVERSE[math.random(1, 2)]

		local mainSide = Vector2.new(math.random() * xFactor, math.random() * yFactor).Unit * enemyGroup.distance

		local corePos = Vector3.new(plrCore.Position.X, groundLevel, plrCore.Position.Z)

		local mainPos = Vector3.new(mainSide.X, groundLevel, mainSide.Y) + corePos * Vector3.new(1, 0, 1)

		local mainCF = CFrame.new(mainPos, corePos)

		local emptyPos = createArmyPos(enemyGroup)

		for id, enemy in enemyGroup.enemy do
			for _ = 1, enemy.size do
				local deltaPos = ArrayUtils.popRandom(emptyPos)

				local cf = mainCF * CFrame.new(deltaPos.X, 0, deltaPos.Y - enemyGroup.spreadFactor)

				local enemyInfo = Enemy(id)
				local pos = cf.Position + Vector3.new(0, enemyInfo.height, 0)

				local statePos: StatePos = {
					IdWave = tostring(idIncr),
					Pos = pos,
					Velocity = Vector3.zero,
				}

				local initInfo: InitInfo = {
					IdInfo = id,
					IdWave = tostring(idIncr),
					TimeSpawn = time() + enemyGroup.time,
				}

				idIncr += 1

				waveData[statePos.IdWave] = statePos
				waveInit[statePos.IdWave] = initInfo
			end
		end
	end

	return waveData, waveInit
end

-- ╔═══════════════════╗
-- ║  Wave Management  ║
-- ╚═══════════════════╝
local TICK_RATE = 1 / 15 -- 20Hz
local _MAX_PACKET_SIZE = 50

type PlayerWave = {
	WaveData: WaveData,
	WaveInfo: WaveInit,
	WaveSpawned: WaveData,
	WaveHandler: RBXScriptConnection,
	DeltaIncrement: number,
}

WaveService.PlayerWave = {} :: {
	[Player]: PlayerWave,
}
function SerializeWaveData(waveData: WaveData, targetPos: Vector3)
	local count = 0
	for _, _ in waveData do
		count += 1
	end

	local buff = buffer.create(count * 5)
	local offset = 0
	for id, statePos in waveData do
		local idNumber = tonumber(id)

		assert(idNumber, "The id string is not a number")

		buffer.writeu8(buff, offset, idNumber)

		local relativePos = statePos.Pos - targetPos

		buffer.writei16(buff, offset + 1, math.round(relativePos.X * 100))

		buffer.writei16(buff, offset + 3, math.round(relativePos.Z * 100))

		offset += 5
	end

	return buff
end

function isEmpty(tab: { [string]: any })
	for _, _ in tab do
		return false
	end
	return true
end

function ManageSpawn(wave: PlayerWave)
	for id, statePos in wave.WaveData do
		local initInfo = wave.WaveInfo[id]
		local timeSpawn = initInfo.TimeSpawn

		if timeSpawn >= time() then
			continue
		end
		wave.WaveSpawned[id] = statePos
		wave.WaveData[id] = nil
	end
end

function ManageMovement(wave: PlayerWave, dt: number, targetPos: Vector3, radius: number)
	--grid
	local grid = buildGrid(wave.WaveSpawned)

	--manage the enemy movement
	for id, statePos in wave.WaveSpawned do
		local idInfo = wave.WaveInfo[id].IdInfo
		local speed = Enemy(idInfo).Speed

		ApplyVelocityFromTarget(statePos, targetPos, dt, speed)

		local neighbors = getNeighbors(grid, statePos.Pos)

		local push = GetPushFromNeighbors(statePos, neighbors, speed)

		local pushCore = GetPushFromCore(statePos, targetPos, speed, radius)

		statePos.Velocity += pushCore * dt

		statePos.Velocity += push * dt

		local maxVelocity = speed * 2.5
		local velocity = statePos.Velocity.Magnitude

		if velocity > maxVelocity then
			statePos.Velocity = statePos.Velocity.Unit * maxVelocity
		end

		statePos.Pos += statePos.Velocity * dt
	end
end

--Main
function HandleWaveMovement(plr: Player, dt: number)
	local wave = WaveService.PlayerWave[plr]

	if not wave then
		return
	end

	if plr.Parent ~= Players then
		wave.WaveHandler:Disconnect()
		return
	end

	if isEmpty(wave.WaveData) and isEmpty(wave.WaveSpawned) then
		print("You finished the wave")
		wave.WaveHandler:Disconnect()
		return
	end

	ManageSpawn(wave)

	if isEmpty(wave.WaveSpawned) then
		return
	end

	local targetPos = PlotService:GetCore(plr).Position
	local radius = PlotService:GetCoreRadius(plr)
	ManageMovement(wave, dt, targetPos, radius)

	wave.DeltaIncrement += dt
	--sync the enemy position
	if wave.DeltaIncrement >= TICK_RATE then
		wave.DeltaIncrement = 0

		local waveData = SerializeWaveData(wave.WaveSpawned, targetPos)

		EnemyTracker:FireUnreliable(plr, waveData)
	end
end

function SyncWave(plr: Player, waveInit: WaveInit, waveData: WaveData)
	WaveSync:Fire(plr, waveInit)

	EnemyService.InitializeFromWave(plr, waveInit)

	local con = RunService.Heartbeat:Connect(function(dt)
		HandleWaveMovement(plr, dt)
	end)

	WaveService.PlayerWave[plr] = {
		WaveData = waveData,
		WaveInfo = waveInit,
		WaveSpawned = {},
		WaveHandler = con,
		DeltaIncrement = 0,
	}
end

function waveRequest(plr: Player)
	--TODO logic to get wave
	local waveData, waveInit = BuildWave(Wave("1"), plr)

	SyncWave(plr, waveInit, waveData)
end

WaveSync:Once(waveRequest)

-- ╔════════════╗
-- ║  Cleaning  ║
-- ╚════════════╝

local function cleanPlr(plr: Player)
	if not WaveService.PlayerWave[plr] then
		return
	end
	WaveService.PlayerWave[plr].WaveHandler:Disconnect()
	WaveService.PlayerWave[plr] = nil
end

Players.PlayerRemoving:Connect(cleanPlr)

-- ╔═════════════════════╗
-- ║  External Function  ║
-- ╚═════════════════════╝

function WaveService.GetPos(plr: Player, idWave: { string }): { [string]: Vector3 }?
	if not WaveService.PlayerWave[plr] then
		return nil
	end

	local wave = WaveService.PlayerWave[plr].WaveSpawned

	local pos = {}

	for _, id in idWave do
		if not wave[id] or type(id) ~= "string" then
			continue
		end
		pos[id] = wave[id].Pos
	end

	return pos
end

function KillEnemy(plr: Player, idWave: { string })
	if not WaveService.PlayerWave[plr] then
		return
	end

	local wave = WaveService.PlayerWave[plr]

	for _, id in idWave do
		wave.WaveData[id] = nil
		wave.WaveSpawned[id] = nil
		wave.WaveInfo[id] = nil
	end
end

EnemyService.enterKillPower(KillEnemy)

return WaveService
