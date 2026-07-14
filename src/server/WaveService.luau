--Discord: _iwa. Roblox: Thuglife09877

-- This is a server-side wave replication script. This script is meant to spawn waves targeting a core that is specific to each player in their plots.
-- This script is a condensed version of another script. It was condensed by removing scalability aspects such as PlotService, a Wave Maker and an entity info list.
-- Instead, These parts were hardcoded to keep things focused on the essentials

-- The movement of the entities is inspired by the "Steering behaviors". It makes them moves and collides like Minecraft Entities

-- ╔═════════════════╗
-- ║  Exemple : foo  ║
-- ╚═════════════════╝
-- The header above was created via JavaScript on a website
-- These headers will be used to better separate my code according to its logic and improve readability

-- This script is separated into 4 Chapters:

-- Chapter 1: Utils
--	+ Array & Maps Utils
--	+ Grid Utils
--	+ Steering Based Velocity Utils
--	+ Wave creation Utils

-- Chapter 2: Entity Class
--	+ It's a small chapter

-- Chapter 3 : WaveState Class
--	+ Initialization & End of life (cleaning)
--	+ Entity's Builder & Wave Start
--	+ Wave Management
--	+ Replication
--	+ Main Loop(Heartbeat)
--	+ State Management

-- Chapter 4 : WaveService
--	+ Initialization & End of life
--	+ Handler
--	+ External Methods

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

-- Instead of doing table.remove(random) which is O(1..n)
-- I do this which is O(1)
function Utils.PopRandom<T>(array: { T }): T
	local index = math.random(1, #array)
	local value = array[index]
	array[index] = array[#array]
	array[#array] = nil
	return value
end

-- We cant get the length of a map via "#map"
-- I mainly need the length of a map to know if its empty
-- Instead of doing a O(n), I do this O(1)
function Utils.IsEmpty(map: { [any]: any }): boolean
	for _, _ in map do
		return false
	end
	return true
end

-- ╔══════════════╗
-- ║  Grid Utils  ║
-- ╚══════════════╝
-- The grid is used to search the nearby entities to collide them.
-- Instead of doing a O(n^2) loop to check if one entity is close to another,
-- We do an O(n) loop first to build the grid and after we do another O(n) loop to get the neighbor cell
-- Result: O(2n)
local GridParams = {
	CELL_SIZE = 4, -- studs
}

type Cell<Content> = { [string]: Content }
type SpatialGrid<Content> = { [string]: Cell<Content> }
type SteeringInfo = { Pos: Vector3, Velocity: Vector3, Speed: number }

-- The grid is going to be a 1 dimensional map
-- So we put the x and y in the same key separated by a ","
function Utils.GetKey(position: Vector3): string
	local x = math.floor(position.X / GridParams.CELL_SIZE)
	local z = math.floor(position.Z / GridParams.CELL_SIZE)
	return x .. "," .. z
end

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
-- This part is really inspired by the "Steering Behaviors"
-- It cost less than the Roblox's humanoid movement when I just want the entities to go in a straight line
-- and react to their neighbors
local VelocityParams = {
	SEPARATION_RADIUS = 3.5,
	SEPARATION_STRENGTH = 1e3,
	TARGET_STRENGTH = 1e4,
}

-- The collision are smooth because they act like reversed magnet. The closer they are, the higher the push
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

		-- the strength is a reversed ratio to make the ratio higher when close
		local strength = (VelocityParams.SEPARATION_RADIUS - distance) / VelocityParams.SEPARATION_RADIUS

		push += diff.Unit * strength * VelocityParams.SEPARATION_STRENGTH * entity.Speed
	end

	return push * Vector3.new(1, 0, 1) --We dont want entities to go on top of a crowd
end

-- work like the pushFromNeighbors
function Utils.GetPushFromTarget(entity: SteeringInfo, targetPos: Vector3, radius: number)
	local targetPos2 = Vector3.new(targetPos.X, entity.Pos.Y, targetPos.Z) -- we put the position to the same level as the entity

	local diff = entity.Pos - targetPos2

	local dist = diff.Magnitude

	local push = Vector3.zero

	if dist < radius and dist > 0.001 then
		local strength = (radius - dist) / radius
		push += diff.Unit * strength * VelocityParams.TARGET_STRENGTH * entity.Speed
	end

	return push * Vector3.new(1, 0, 1)
end

function Utils.ApplyVelocityFromTarget(entity: Entity, targetPos: Vector3)
	targetPos = Vector3.new(targetPos.X, entity.Pos.Y, targetPos.Z)

	local diff = (targetPos - entity.Pos)

	if diff.Magnitude > 0.001 then
		entity.Velocity = diff.Unit * entity.Speed
	end
end

-- ╔═══════════════════════╗
-- ║  Wave Creation Utils  ║
-- ╚═══════════════════════╝
--This part is used to make the entity spawn together in a group

type EntityGroup = {
	Count: number,
	distance: number,
	spreadFactor: number, -- work likes a padding
	dimension: Vector2,
	timeSpawn: number,
}

type Wave = { EntityGroup }

local waveHolder: Wave = {
	{
		Count = 10,
		distance = 40,
		spreadFactor = 3,
		dimension = Vector2.new(5, 2), -- 2 rows of 5 entities
		timeSpawn = 5,
	},
}

-- return an array of x,z positions representing the offset from the front center
-- Determine whether the row width is odd or even and center the row
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

local SIDE = { -1, 1 }
function Utils.ChooseSide(entityGroup: EntityGroup, targetPos: Vector3, groundLevel: number): CFrame
	local xFactor = SIDE[math.random(1, 2)]
	local yFactor = SIDE[math.random(1, 2)]

	local mainSide = Vector2.new(math.random() * xFactor, math.random() * yFactor).Unit * entityGroup.distance

	local corePosGround = Vector3.new(targetPos.X, groundLevel, targetPos.Z)

	local mainPos = Vector3.new(mainSide.X, groundLevel, mainSide.Y) + corePosGround * Vector3.new(1, 0, 1)

	return CFrame.new(mainPos, corePosGround)
end

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

local Entity = {}
Entity.__index = Entity
--These are for all the entities
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

	Utils.ApplyVelocityFromTarget(self, target)

	push += Utils.GetPushFromNeighbors(steeringInfo, neighbors)
	push += Utils.GetPushFromTarget(steeringInfo, target, radius)

	self.Velocity += push * delta

	local maxVelocity = self.Speed * 2.5
	local velocity = self.Velocity.Magnitude

	--in case there is a huge push, there is a limit
	if velocity > maxVelocity then
		self.Velocity = self.Velocity.Unit * maxVelocity
	end

	self.Pos += self.Velocity * delta
end

-- ╔════════════════════════╗
-- ║  Chapter 3: WaveState  ║
-- ╚════════════════════════╝

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

-- ╔════════════════════════════════════════════╗
-- ║  WaveState : Initialization & End of life  ║
-- ╚════════════════════════════════════════════╝

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

function WaveState.InitSync(self: WaveState)
	local UserId = self.Player.UserId
	-- Those atoms are unique to the players, so I have to make them unique with the userId.
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

	-- Usually, the waveState is in a {[plr]:WaveState} so we set it to nil elsewhere
end

-- When the wave end, we call this to reset for the next wave
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

-- ╔═════════════════════════════════════════════╗
-- ║  WaveState : Entity's Builder & Wave Start  ║
-- ╚═════════════════════════════════════════════╝

-- There are two ways to do this
-- 1. Table clone everytime and set the health(BAD)
-- 2. table clone one time and set the health in a task.defer(GOOD)

-- the first is the worst because a table clone is O(n) and this method is called inside of a loop = O(n^2)
-- the 2nd is the best because we call once a table.clone when the first entity is created.
-- We use the same cloned table for the other entities in the resumption cycle = O(n)
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

-- we make sure the status is None because there might be some problem to start a wave when there is already a wave
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

--In this function, we switch the resting Entities that are ready to spawn to the actives Entities.
-- Doing this will start the replication for the new active entities
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

-- if we add more behavior, we add them here in the loop
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
-- In this part, we are using buffers inside of Unreliable Events

local MAX_PAYLOAD_BYTES = 850 -- the max for unreliableEvent is around 900
local BYTES_PER_ENTITY = 5 -- the first byte is the id, 2 for the x and 2 for the z
local MAX_ENTITIES_PER_CHUNK = MAX_PAYLOAD_BYTES // BYTES_PER_ENTITY

local POSITION_PRECISION_SCALE = 100 -- we send integers in the buffer, so to keep some decimal value we do *100 and /100 on the client side
local MAX_REPLICATION_DISTANCE = 2 ^ 15 / POSITION_PRECISION_SCALE

local TICK_RATE = 1 / 15 -- 15Hz

-- The position is not based off the worldSpace, because the position is based around the center of the world.
-- Instead, The target is the center (objectSpace) . We serialize the relative position of the entities based off the target position
-- On the client side we just do: targetPos + relativePos
-- To respect the limit of the Unreliable event, we make make a table of buffers that are not exceeding 850 bytes
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

-- We send the position at 15 Hz frequency, it is the limit to keep the position smooth on the client side
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

-- This the method that is going to be called inside of heartbeat
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

-- we save the the RBXScriptConnection inside of self.Replicator to cancel it when needed
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

-- This is the method that is going to be called by external Services to apply damage to the entities
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

-- This is the method that is going to be called by external Services to validate if the entities are in the range of an attack or etc..
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

-- I check if the health map is empty when the WaveStatus is "Active" to switch the status to "Completed"
function WaveState.HandleWin(self: WaveState)
	table.insert(
		self.Cleaner,
		Charm.subscribe(self.Health, function(state, lastState)
			if not Utils.IsEmpty(state) or self.Status() ~= WaveState.Enum.Active then
				return
			end

			self.Status(WaveState.Enum.Completed)
		end)
	)
end

-- ╔═══════════════════════════╗
-- ║  Chapter 4 : WaveService  ║
-- ╚═══════════════════════════╝
-- This part is for the main Service of the script

local WaveService = {}

type WaveService = WaveService_Method & {
	Cleaner: { [Player]: { [any]: () -> () } },
	WaveState: { [Player]: WaveState },
	OnCompleted: { [Player]: { () -> () } },
}

-- ╔══════════════════════════════════════════════╗
-- ║  WaveService : Initialization & End of life  ║
-- ╚══════════════════════════════════════════════╝

--If I dont do this, the type checker is angry at me
function WaveService:Init()
	return self:Build()
end

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

	CharmSync.config.fixArrays = false -- Im using a networking library(blink), I have to set it to false
	CharmSync.server.connect(function(client: Player, payloads)
		Blink.Sync.Fire(client, payloads)
	end)

	return self
end

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
-- we start a wave when requested, we cannot start the wave if the Status isn't "None"
function WaveService.HandleRequest(self: WaveService, plr: Player)
	local state = self.WaveState[plr]

	if not state or state.Status() ~= WaveState.Enum.None then
		return
	end

	state:StartWave(waveHolder)
end

-- We add some effect when the status has changed, When the status is "Completed" we switch it to None after 1 sec
-- When "None", I reset the wave for the next wave,
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
-- If we want to add some effect to a wave Completion, we call this method
function WaveService.SubscribeToCompleted(self: WaveService, plr: Player, callback: () -> ())
	if not self.WaveState[plr] then
		self:InitPlr(plr)
	end

	table.insert(self.OnCompleted[plr], callback)
end
-- For external services, mainly used to call the ApplyDamage and GetEntitiesPos
function WaveService.GetState(self: WaveService, plr: Player): WaveState
	if not self.WaveState[plr] then
		self:InitPlr(plr)
	end

	return self.WaveState[plr]
end

type WaveService_Method = typeof(WaveService)

return WaveService:Init() :: WaveService
