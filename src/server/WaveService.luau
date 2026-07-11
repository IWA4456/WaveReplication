--Discord: _iwa.  Roblox: Thuglife09877

-- Server-side wave system: spawns groups of enemies around a target,
-- steers them with spatial-hash-based separation, tracks health/status per
-- player via Charm, and replicates positions to clients over Blink using a
-- fixed-point buffer encoding.

--[[
	╔══════════════════════════════════════════════════════════════════════╗
	║                          TABLE OF CONTENTS                           ║
	╠══════════════════════════════════════════════════════════════════════╣
	║  Chapter 1 : Utils                                                   ║
	║    - Array/Map helpers        -> PopRandom, IsEmpty                  ║
	║    - Spatial hashing grid     -> GetKey, buildGrid, GetNeighbors     ║
	║    - Steering math            -> GetPushFromNeighbors,               ║
	║                                   GetPushFromTarget,                 ║
	║                                   ApplyVelocityFromTarget            ║
	║    - Wave layout generation   -> CreateCrowdPos,ChooseSide,BuildWave ║
	║                                                                      ║
	║  Chapter 2 : Entity                                                  ║
	║    - Per-enemy state (no Humanoid) and velocity integration          ║
	║                                                                      ║
	║  Chapter 3 : WaveState                                               ║
	║    - Per-player wave lifecycle (one instance per Player)             ║
	║    - Charm atoms for Health/Status/TargetPosition                    ║
	║    - Buffer-based position replication (fixed-point i16 encoding)    ║
	║                                                                      ║
	║  Chapter 4 : WaveService                                             ║
	║    - Orchestrates WaveState per player, wires Blink + CharmSyn       ║
	╚══════════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blink = require(script.Parent.Blink)
local Charm = require(ReplicatedStorage.Packages.Charm)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
-- ╔═════════════════════╗
-- ║  Chapter 1 : Utils  ║
-- ╚═════════════════════╝
local Utils = {}

-- ╔═══════════════════════╗
-- ║  Arrays & Maps Utils  ║
-- ╚═══════════════════════╝

-- Swap-remove: O(1), don't care about order. Used to consume random spawn
-- positions in BuildWave.
function Utils.PopRandom<T>(array: { T }): T
	local index = math.random(1, #array)
	local value = array[index]
	array[index] = array[#array]
	array[#array] = nil
	return value
end

-- `#map` doesn't work on our id-keyed maps, so just check for one key.
function Utils.IsEmpty(map: { [any]: any })
	for _, _ in map do
		return false
	end
	return true
end

-- ╔══════════════╗
-- ║  Grid Utils  ║
-- ╚══════════════╝
-- Spatial hashing. Cell size ~1x SEPARATION_RADIUS so neighbors are always
-- in the same or adjacent cell - GetNeighbors only needs a 3x3 scan.
local GridParams = {
	CELL_SIZE = 4, -- studs
}

type Cell<Content> = { [string]: Content }
type SpatialGrid<Content> = { [string]: Cell<Content> }
type SteeringInfo = { Pos: Vector3, Velocity: Vector3, Speed: number }

-- String key ("x,z") instead of a packed number, mostly for readability
-- when debugging.
function Utils.GetKey(position: Vector3): string
	local x = math.floor(position.X / GridParams.CELL_SIZE)
	local z = math.floor(position.Z / GridParams.CELL_SIZE)
	return x .. "," .. z
end

-- Rebuilt every tick instead of updated incrementally - entities move every
-- frame anyway, so incremental tracking wouldn't save much.
function Utils.buildGrid(entities: { [string]: Entity }): SpatialGrid<Entity>
	local grid: SpatialGrid<Entity> = {}

	for id, entity in entities do
		local key = Utils.GetKey(entity.Pos)

		if not grid[key] then
			grid[key] = {}
		end

		grid[key][id] = entity
	end

	return grid
end

-- 3x3 scan around the entity's cell instead of checking every entity.
function Utils.GetNeighbors(grid: SpatialGrid<SteeringInfo>, position: Vector3): { SteeringInfo }
	local neighbours = {}
	local cx = math.floor(position.X / GridParams.CELL_SIZE)
	local cz = math.floor(position.Z / GridParams.CELL_SIZE)

	for dx = -1, 1 do
		for dz = -1, 1 do
			local key = (cx + dx) .. "," .. (cz + dz)

			if not grid[key] then
				continue
			end

			for _, entity in grid[key] do
				table.insert(neighbours, entity)
			end
		end
	end

	return neighbours
end

-- ╔═════════════════════════════════╗
-- ║  Steering-Based Velocity Utils  ║
-- ╚═════════════════════════════════╝
-- Strengths are big (1e3/1e4) because they get multiplied by dt before
-- being added to velocity. Kept separate from Entity.Speed so push force
-- and walk speed can be tuned independently.
local VelocityParams = {
	SEPARATION_RADIUS = 3.5,
	SEPARATION_STRENGTH = 1e3,
	TARGET_STRENGTH = 1e4,
}

-- Boids-style separation: push away from neighbors inside SEPARATION_RADIUS,
-- stronger the closer they are. Flattened to XZ since enemies don't move
-- vertically.
function Utils.GetPushFromNeighbors(entity: SteeringInfo, neighbors: { SteeringInfo })
	local push = Vector3.zero

	for _, other in neighbors do
		if other == entity then
			continue
		end

		local diff = entity.Pos - other.Pos

		local distance = diff.Magnitude

		if distance > VelocityParams.SEPARATION_RADIUS or distance < 0.001 then
			continue
		end

		local strength = (VelocityParams.SEPARATION_RADIUS - distance) / VelocityParams.SEPARATION_RADIUS

		push += diff.Unit * strength * VelocityParams.SEPARATION_STRENGTH * entity.Speed
	end

	return push * Vector3.new(1, 0, 1)
end

-- Anti-clump: push away from the target once inside `radius`, so entities
-- don't all stack on the exact same point.
function Utils.GetPushFromTarget(entity: SteeringInfo, targetPos: Vector3, radius: number)
	local targetPos2 = Vector3.new(targetPos.X, entity.Pos.Y, targetPos.Z)

	local diff = entity.Pos - targetPos2

	local dist = diff.Magnitude

	local push = Vector3.zero

	if dist < radius and dist > 0.001 then
		local strength = (radius - dist) / radius
		push += diff.Unit * strength * VelocityParams.TARGET_STRENGTH * entity.Speed
	end

	return push * Vector3.new(1, 0, 1)
end

-- Base seek: point velocity at the target. Runs before the pushes get
-- added on top in UpdateVelocity.
function Utils.ApplyVelocityFromTarget(entity: Entity, targetPos: Vector3, dt: number)
	targetPos = Vector3.new(targetPos.X, entity.Pos.Y, targetPos.Z)

	local diff = (targetPos - entity.Pos)

	if diff.Magnitude > 0.001 then
		entity.Velocity = diff.Unit * entity.Speed
	end
end

-- ╔═══════════════════════╗
-- ║  Wave Creation Utils  ║
-- ╚═══════════════════════╝

type EntityGroup = {
	Count: number,
	distance: number,
	spreadFactor: number,
	dimension: Vector2,
	timeSpawn: number,
}

type Wave = { EntityGroup }

local waveHolder: Wave = {
	{
		Count = 10,
		distance = 40,
		spreadFactor = 3,
		dimension = Vector2.new(5, 2), -- the units is based on Entities, so it's 2 rows of 5 entities
		timeSpawn = 5,
	},
}

-- Lays out a centered grid of spawn positions for one EntityGroup. Handles
-- even/odd column counts separately so it's always centered on X = 0.
function Utils.CreateCrowdPos(entityGroup: EntityGroup): { Vector2 }
	local dimension = entityGroup.dimension

	local isEvenAxisX = dimension.X % 2 == 0

	local centerIndex = isEvenAxisX and dimension.X / 2 or (dimension.X + 1) / 2

	local centerPos = Vector2.zero
	if isEvenAxisX then
		centerPos = Vector2.new(-entityGroup.spreadFactor / 2, 0)
	end

	local tablePos = {}

	for x = 1, dimension.X do
		local diffCenter = x - centerIndex
		local xPos = centerPos.X + entityGroup.spreadFactor * diffCenter

		for y = 1, dimension.Y do
			table.insert(tablePos, Vector2.new(xPos, entityGroup.spreadFactor * y))
		end
	end

	return tablePos
end

-- Picks a random side around the target and returns a CFrame there facing
-- back at it - the local-space origin BuildWave spawns the crowd grid from.
local SIDE = { -1, 1 }
function Utils.ChooseSide(entityGroup: EntityGroup, targetPos: Vector3, groundLevel: number): CFrame
	local xFactor = SIDE[math.random(1, 2)]
	local yFactor = SIDE[math.random(1, 2)]

	local mainSide = Vector2.new(math.random() * xFactor, math.random() * yFactor).Unit * entityGroup.distance

	local corePosGround = Vector3.new(targetPos.X, groundLevel, targetPos.Z)

	local mainPos = Vector3.new(mainSide.X, groundLevel, mainSide.Y) + corePosGround * Vector3.new(1, 0, 1)

	return CFrame.new(mainPos, corePosGround)
end

-- For each EntityGroup, picks a side, lays out the crowd grid, converts it
-- to world space and hands each position to `factory`. Rig height comes
-- from GetBoundingBox so entities spawn standing on the ground.
function Utils.BuildWave(props: {
	targetPos: Vector3,
	groundLevel: number,
	wave: Wave,
	RigTemplate: Model,
	factory: (id: string, pos: Vector3, timeSpawn: number) -> (),
})
	local id = 1
	local _, size = props.RigTemplate:GetBoundingBox()
	local height = size.Y / 2

	for _, entityGroup in props.wave do
		local side = Utils.ChooseSide(entityGroup, props.targetPos, props.groundLevel)
		local crowdPos = Utils.CreateCrowdPos(entityGroup)

		for _ = 1, entityGroup.Count do
			local selectedPos = Utils.PopRandom(crowdPos)

			local cf = side * CFrame.new(selectedPos.X, 0, selectedPos.Y - entityGroup.spreadFactor)
			local pos = cf.Position + Vector3.yAxis * height

			props.factory(tostring(id), pos, entityGroup.timeSpawn + time())
			id += 1
		end
	end
end

-- ╔════════════════════════════╗
-- ║  Chapter 2 : Entity Class  ║
-- ╚════════════════════════════╝
-- Plain metatable class instead of Humanoid: no pathing/physics overhead,
-- and it's the only way to get custom steering (Humanoid doesn't expose
-- separation behavior).

-- Entity.Speed/Health are hardcoded on purpose - this is meant to show off
-- the wave system itself, not a scalable multi-enemy setup, so I'm skipping
-- the config layer that would need.
local Entity = {}
Entity.__index = Entity
Entity.Speed = 3
Entity.Health = 10

type Entity = typeof(setmetatable(
	{} :: {
		Id: string,
		Pos: Vector3,
		Velocity: Vector3,
		TimeSpawn: number,
	},
	Entity
))

function Entity.New(id: string, pos: Vector3, timeSpawn: number): Entity
	local self: Entity = setmetatable({
		Id = id,
		Pos = pos,
		Velocity = Vector3.zero,
		TimeSpawn = timeSpawn,
	}, Entity)

	return self
end

-- Seek toward target, add both steering pushes, clamp to 2.5x Speed, then
-- integrate position. Velocity is fully resolved before Pos moves, so both
-- push functions read a consistent snapshot (`steeringInfo`).
function Entity.UpdateVelocity(
	self: Entity,
	neighbors: { SteeringInfo },
	target: Vector3,
	delta: number,
	radius: number
)
	local push = Vector3.zero

	local steeringInfo: SteeringInfo = {
		Pos = self.Pos,
		Velocity = self.Velocity,
		Speed = self.Speed,
	}

	Utils.ApplyVelocityFromTarget(self, target, delta)

	push += Utils.GetPushFromNeighbors(steeringInfo, neighbors)
	push += Utils.GetPushFromTarget(steeringInfo, target, radius)

	self.Velocity += push * delta

	local maxVelocity = self.Speed * 2.5
	local velocity = self.Velocity.Magnitude

	if velocity > maxVelocity then
		self.Velocity = self.Velocity.Unit * maxVelocity
	end

	self.Pos += self.Velocity * delta
end

-- ╔════════════════════════╗
-- ║  Chapter 3: WaveState  ║
-- ╚════════════════════════╝
-- One WaveState per player - each player's wave is fully independent, and
-- cleanup on leave is just dropping the WaveState.

local WaveState = {}
WaveState.__index = WaveState
WaveState.Enum = {
	None = 0,
	Active = 1,
	Completed = 2,
}

type EntityId = string

type WaveStatus = number

type WaveState = typeof(setmetatable(
	{} :: {
		ActiveEntities: { [EntityId]: Entity },
		RestingEntities: { [EntityId]: Entity },
		Health: Charm.Atom<{ [EntityId]: number }>,
		Status: Charm.Atom<WaveStatus>,
		TargetPosition: Charm.Atom<Vector3>,
		TargetRadius: number,
		Cleaner: { [any]: () -> () },
		Player: Player,
		HzIncrement: number,
		Replicator: RBXScriptConnection?,
		BuildingHealth: { [EntityId]: number }?,
	},
	WaveState
))

function WaveState.New(plr: Player): WaveState
	local self: WaveState = setmetatable({
		Player = plr,
		RestingEntities = {},
		ActiveEntities = {},
		Cleaner = {},
		HzIncrement = 0,
		Health = Charm.atom({}),
		Status = Charm.atom(WaveState.Enum.None),
		TargetPosition = Charm.atom(Vector3.zero),
		TargetRadius = 8,
	}, WaveState)

	self:InitSync()

	self:HandleWin()

	return self
end

-- Health/Status are only meaningful to this player, so they're registered
-- under player-scoped signal names instead of synced globally.
function WaveState.InitSync(self: WaveState)
	local UserId = self.Player.UserId

	CharmSync.server.addSignalsToClient(self.Player, {
		[`EntitiesHealth-{UserId}`] = self.Health,
		[`WaveStatus-{UserId}`] = self.Status,
	})
end

function WaveState.Clean(self: WaveState)
	for _, clean in self.Cleaner do
		clean()
	end

	if self.Replicator then
		self.Replicator:Disconnect()
	end
end

function WaveState.ResetWave(self: WaveState)
	if self.Replicator then
		self.Replicator:Disconnect()
		self.Replicator = nil
	end

	self.ActiveEntities = {}
	self.RestingEntities = {}

	self.BuildingHealth = nil

	self.Health({})
end

-- ╔═══════════════════════╗
-- ║  WaveState : Builder  ║
-- ╚═══════════════════════╝

-- Spawning N entities in the same frame would otherwise call self.Health(...)
-- N times, and each write needs its own clone - O(n²) over a spawn burst.
-- `BuildingHealth` batches this: clone once per frame, mutate that clone for
-- every entity spawned, flush with a single task.defer.
function WaveState.NewEntity(self: WaveState, id: string, pos: Vector3, timeSpawn: number)
	local entity = Entity.New(id, pos, timeSpawn)

	self.RestingEntities[id] = entity

	if self.BuildingHealth then
		self.BuildingHealth[id] = entity.Health
		return entity
	end

	self.BuildingHealth = table.clone(self.Health())

	task.defer(function()
		if not self.BuildingHealth then
			return
		end
		self.BuildingHealth[id] = entity.Health

		self.Health(self.BuildingHealth)

		self.BuildingHealth = nil
	end)

	return entity
end

-- Guarded so a player can't stack multiple waves at once.
--
-- waveHolder and the Rig/Target/Baseplate paths below are hardcoded on
-- purpose - one enemy type, one wave, one target, nothing to configure yet.
function WaveState.StartWave(self: WaveState, wave: { EntityGroup })
	if self.Status() ~= WaveState.Enum.None then
		return
	end

	local rig: Model = ReplicatedStorage.Rig.Noob
	local target: BasePart = workspace.Target

	local ground: Part = workspace.Baseplate
	local groundLevel = ground.Position.Y + ground.Size.Y / 2

	Utils.BuildWave({
		RigTemplate = rig,
		groundLevel = groundLevel,
		targetPos = target.Position,
		wave = wave,
		factory = function(id, pos, timeSpawn)
			self:NewEntity(id, pos, timeSpawn)
		end,
	})

	self.TargetPosition(target.Position)

	self:StartReplication()

	self.Status(WaveState.Enum.Active)
end

-- ╔═══════════════════════════════╗
-- ║  WaveState : Wave Management  ║
-- ╚═══════════════════════════════╝

-- Checks TimeSpawn against time() every frame instead of scheduling a
-- delayed thread per entity - cheaper and nothing to cancel on cleanup.
function WaveState.ManageSpawn(self: WaveState)
	for id, state in self.RestingEntities do
		local timeSpawn = state.TimeSpawn
		if timeSpawn > time() then
			continue
		end
		self.ActiveEntities[id] = state
		self.RestingEntities[id] = nil
	end
end

function WaveState.ManageBehavior(self: WaveState, dt: number)
	local spatialGrid = Utils.buildGrid(self.ActiveEntities)

	for _, entity in self.ActiveEntities do
		local neighbors = Utils.GetNeighbors(spatialGrid, entity.Pos)

		entity:UpdateVelocity(neighbors, self.TargetPosition(), dt, self.TargetRadius)
	end
end

-- ╔═══════════════════════════╗
-- ║  WaveState : Replication  ║
-- ╚═══════════════════════════╝

-- Positions replicated as fixed-point i16s instead of floats: 5 bytes per
-- entity (id + relative X/Z) instead of 12+ for a raw Vector3. Relative to
-- TargetPosition (not world pos) so the range stays small enough to fit.
local MAX_PAYLOAD_BYTES = 850
local BYTES_PER_ENTITY = 5
local MAX_ENTITIES_PER_CHUNK = MAX_PAYLOAD_BYTES // BYTES_PER_ENTITY

local POSITION_PRECISION_SCALE = 100
-- i16 range is -32768..32767, so 2^15 is the max scaled distance that fits.
local MAX_REPLICATION_DISTANCE = 2 ^ 15 / POSITION_PRECISION_SCALE

local TICK_RATE = 1 / 15 -- 15Hz

-- Chunked so a big wave doesn't produce one oversized unreliable payload.
function WaveState.Serialize(self: WaveState): { buffer }
	local entities = {}
	for id, state in self.ActiveEntities do
		table.insert(entities, { id = id, state = state })
	end

	local chunks: { buffer } = {}
	local entityCount = #entities

	for chunkStart = 1, entityCount, MAX_ENTITIES_PER_CHUNK do
		local chunkEnd = math.min(chunkStart + MAX_ENTITIES_PER_CHUNK - 1, entityCount)
		local chunkSize = chunkEnd - chunkStart + 1

		local buff = buffer.create(chunkSize * BYTES_PER_ENTITY)
		local offset = 0

		for i = chunkStart, chunkEnd do
			local entry = entities[i]
			local idNumber = tonumber(entry.id)
			assert(idNumber, "The id string is not a number")

			local relativePos = entry.state.Pos - self.TargetPosition()
			if relativePos.Magnitude > MAX_REPLICATION_DISTANCE then
				-- NOTE: skipped entities leave trailing zero-bytes since the
				-- buffer keeps its full chunk size. Client decode needs to
				-- stop at `offset`, not at buffer length.
				continue
			end

			buffer.writeu8(buff, offset, idNumber)
			buffer.writei16(buff, offset + 1, math.round(relativePos.X * POSITION_PRECISION_SCALE))
			buffer.writei16(buff, offset + 3, math.round(relativePos.Z * POSITION_PRECISION_SCALE))

			offset += BYTES_PER_ENTITY
		end

		table.insert(chunks, buff)
	end

	return chunks
end

-- Accumulator decouples replication rate from Heartbeat's actual rate, so
-- it stays close to TICK_RATE regardless of framerate.
function WaveState.SyncPos(self: WaveState, dt: number)
	self.HzIncrement += dt

	if self.HzIncrement < TICK_RATE then
		return
	end

	self.HzIncrement -= TICK_RATE

	local chunks = self:Serialize()

	for _, buff in chunks do
		Blink.UnreliableSync.Fire(self.Player, buff)
	end
end

-- ╔═════════════════════════╗
-- ║  WaveState : Main Loop  ║
-- ╚═════════════════════════╝

function WaveState.UpdateState(self: WaveState, dt: number)
	if Utils.IsEmpty(self.ActiveEntities) and Utils.IsEmpty(self.RestingEntities) then
		return
	end

	self:ManageSpawn()

	if Utils.IsEmpty(self.ActiveEntities) then
		return
	end

	self:ManageBehavior(dt)

	self:SyncPos(dt)
end

function WaveState.StartReplication(self: WaveState)
	if self.Replicator then
		return
	end

	self.Replicator = RunService.Heartbeat:Connect(function(dt: number)
		self:UpdateState(dt)
	end)
end

-- ╔════════════════════════════════╗
-- ║  WaveState : State Management  ║
-- ╚════════════════════════════════╝

-- Batches a group of hits into one Health write instead of one per hit.
function WaveState.ApplyDamage(self: WaveState, ids: { string }, damage: number)
	local health = table.clone(self.Health())

	for _, id in ids do
		local currentHp = health[id]
		local nextHp = math.max(0, currentHp - damage)

		if nextHp <= 0 then
			health[id] = nil
			self.ActiveEntities[id] = nil
			self.RestingEntities[id] = nil
			continue
		end

		health[id] = nextHp
	end

	self.Health(health)
end

function WaveState.GetEntitiesPos(self: WaveState, ids: { string }): { [string]: Vector3 }
	local pos = {}

	for _, id in ids do
		if not self.ActiveEntities[id] then
			continue
		end
		pos[id] = self.ActiveEntities[id].Pos
	end

	return pos
end

-- Subscribed instead of checked inline in ApplyDamage, so "wave cleared"
-- logic lives in one place no matter what emptied Health.
function WaveState.HandleWin(self: WaveState)
	Charm.subscribe(self.Health, function(state, lastState)
		if not Utils.IsEmpty(state) or self.Status() ~= WaveState.Enum.Active then
			return
		end

		self.Status(WaveState.Enum.Completed)
	end)
end

-- ╔═══════════════════════════╗
-- ║  Chapter 4 : WaveService  ║
-- ╚═══════════════════════════╝
-- Singleton that owns one WaveState per player and wires up Blink/CharmSync
-- once, globally.

local WaveService = {}

type WaveService = WaveService_Method & {
	Cleaner: { [Player]: { [any]: () -> () } },
	WaveState: { [Player]: WaveState },
	OnCompleted: { [Player]: { () -> () } },
}

-- ╔════════════════════════════════╗
-- ║  WaveService : Initialization  ║
-- ╚════════════════════════════════╝

function WaveService:Init()
	return self:Build()
end

-- CharmSync.server.connect re-routes atom diffs through Blink's Sync remote
-- instead of CharmSync's default transport, so all networking goes through
-- one Blink-generated schema.
function WaveService.Build(self: WaveService)
	self.Cleaner = {}
	self.WaveState = {}
	self.OnCompleted = {}

	Blink.WaveRequest.On(function(plr: Player)
		self:HandleRequest(plr)
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		self:CleanPlr(plr)
	end)
	Blink.PlayerReady.On(function(plr: Player)
		self:InitPlr(plr)
	end)

	CharmSync.config.fixArrays = false -- I use the Blink networker
	CharmSync.server.connect(function(client: Player, payloads)
		Blink.Sync.Fire(client, payloads)
	end)

	return self
end

-- Guarded so calling this from multiple places never creates two
-- WaveStates for the same player.
function WaveService.InitPlr(self: WaveService, plr: Player)
	if self.WaveState[plr] then
		return
	end

	local waveState = WaveState.New(plr)

	self.WaveState[plr] = waveState
	self.Cleaner[plr] = {}
	self.OnCompleted[plr] = {}

	local cleaner1 = Charm.subscribe(waveState.Status, function(state)
		self:HandleState(plr, state)
	end)

	table.insert(self.Cleaner[plr], function()
		cleaner1()
		waveState:Clean()
	end)
end

function WaveService.CleanPlr(self: WaveService, plr: Player)
	if self.Cleaner[plr] then
		for _, clean in self.Cleaner[plr] do
			clean()
		end
	end

	CharmSync.server.removeClient(plr)

	self.Cleaner[plr] = nil
	self.WaveState[plr] = nil
	self.OnCompleted[plr] = nil
end

-- ╔═════════════════════════╗
-- ║  WaveService : Handler  ║
-- ╚═════════════════════════╝

-- Only accepts a request while Status is None, so spam can't start
-- overlapping waves.
function WaveService.HandleRequest(self: WaveService, plr: Player)
	local state = self.WaveState[plr]

	if not state or state.Status() ~= WaveState.Enum.None then
		return
	end

	state:StartWave(waveHolder)
end

-- Reacts to Status changes instead of WaveState calling back directly, to
-- keep WaveState decoupled from service-level concerns. 1s delay before
-- reset gives the client time to show the "completed" state.
function WaveService.HandleState(self: WaveService, plr: Player, status: number)
	local state = self.WaveState[plr]

	if status == WaveState.Enum.None then
		state:ResetWave()
	elseif status == WaveState.Enum.Completed then
		for _, callback in self.OnCompleted[plr] do
			callback()
		end

		task.delay(1, function()
			state.Status(WaveState.Enum.None)
		end)
	end
end

-- ╔══════════════════════════════════╗
-- ║  WaveService : External Methods  ║
-- ╚══════════════════════════════════╝

-- Lazily inits so other services can subscribe before a player's WaveState
-- exists.
function WaveService.SubscribeToCompleted(self: WaveService, plr: Player, callback: () -> ())
	if not self.WaveState[plr] then
		self:InitPlr(plr)
	end

	table.insert(self.OnCompleted[plr], callback)
end

function WaveService.GetState(self: WaveService, plr: Player): WaveState
	if not self.WaveState[plr] then
		self:InitPlr(plr)
	end

	return self.WaveState[plr]
end

type WaveService_Method = typeof(WaveService)

return WaveService:Init() :: WaveService
