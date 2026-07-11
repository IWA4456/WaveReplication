local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local WaveService = require(script.Parent.WaveService)
local StateFlow = require(ServerScriptService.Server.StateFlow.StateFlow)
local Charm = require(ReplicatedStorage.Packages.Charm)
local DeepEqualizer = require(ReplicatedStorage.Shared.DeepEqualizer)
local WaveState = require(ReplicatedStorage.Shared.Enums.WaveState)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)

-- ╔══════════════════════════════════╗
-- ║  WeaponService : Initialization  ║
-- ╚══════════════════════════════════╝
local Params = {
	DISTANCE_TOLERANCE = 1,
	RADIUS_TOLERANCE = 10,
	JITTER_BUFFER = 0.05,
}

local WeaponService = {}

function WeaponService:Init()
	return self:Build()
end

function WeaponService.Build(self: WeaponService)
	self.PlayerState = {}
	self.Cleaner = {}

	self.RequestHit = Jolt.Server("RequestHit")

	Players.PlayerAdded:Connect(function(plr: Player)
		self:InitPlr(plr)
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		self:CleanPlr(plr)
	end)

	self.RequestHit:Connect(function(plr, ids: { string })
		self:HitValidation(plr, ids)
	end)

	return self
end

function WeaponService.InitPlr(self: WeaponService, plr: Player)
	if self.PlayerState[plr] then
		return
	end

	self.Cleaner[plr] = {}

	local weaponState = self:InitAtoms(plr)

	local state: PlayerState = {
		LastHitRequest = 0,
		WeaponState = weaponState,
	}

	self.PlayerState[plr] = state

	local function EquipTool(char: Model)
		local tool = state.WeaponState.WeaponTool()

		tool.Parent = char
	end

	local cleaner1 = Charm.effect(function()
		local char = plr.Character
		local tool = state.WeaponState.WeaponTool()
		local data = Charm.untracked(state.WeaponState.WeaponData)

		if not tool or not char or not data then
			return
		end

		tool.Name = data.Id

		EquipTool(char)
	end)

	local cleaner2 = plr.CharacterAdded:Connect(function()
		local data = state.WeaponState.WeaponData()

		if not data then
			return
		end

		local info = Weapon.NewFromData(data)
		state.WeaponState.WeaponTool(info:GetTool())
	end)

	table.insert(self.Cleaner[plr], function()
		cleaner1()
		cleaner2:Disconnect()
	end)
end

function WeaponService.InitAtoms(self: WeaponService, plr: Player): WeaponState
	local equipedWeapon: Charm.Atom<Weapon.EquipData> = Charm.atom({ Id = "WoodenSword", Index = 1 })
	local Weapons = Charm.atom({ ["WoodenSword"] = { { Count = 1 } } })

	local weaponData = Charm.computed(function(prev: Weapon.MinData?)
		local inventory = Weapons()
		local EquipData = equipedWeapon()

		local extra = inventory[EquipData.Id][EquipData.Index].Extra

		local data = Weapon.Data(EquipData.Id, extra)

		if prev and DeepEqualizer(prev, data) then
			return prev
		end

		return data
	end)

	--Tool
	local weaponTool = Charm.atom(nil)
	local cleaner2 = Charm.effect(function()
		local tool = weaponTool()
		if not tool then
			return
		end

		return function()
			tool:Destroy()
		end
	end)

	local cleaner1 = Charm.effect(function()
		local data = weaponData()

		if not data then
			return
		end

		local info = Weapon.NewFromData(data)
		local tool = info:GetTool()
		weaponTool(tool)
	end)

	--Cooldown: derived from attackStreak and datainfo
	local CoolDown = Charm.computed(function()
		local data = weaponData()

		if not data then
			return 0
		end

		local info = Weapon.NewFromData(data)

		local coolDown = info.CoolDown + info.Duration

		return coolDown
	end)

	local weaponState: WeaponState = {
		WeaponData = weaponData,
		WeaponTool = weaponTool,
		CoolDown = CoolDown,
		WaveState = WaveService:GetState(plr).Status,
	}

	print(weaponTool().Parent)
	StateFlow:Register(plr, weaponState)

	table.insert(self.Cleaner[plr], function()
		cleaner1()
		cleaner2()
	end)

	return weaponState
end

function WeaponService.CleanPlr(self: WeaponService, plr: Player)
	if self.Cleaner[plr] then
		for _, cleaner in self.Cleaner[plr] do
			cleaner()
		end
	end

	self.Cleaner[plr] = nil
	self.PlayerState[plr] = nil
end

-- ╔══════════════════════════════════╗
-- ║  WeaponService : Hit Validation  ║
-- ╚══════════════════════════════════╝

local function insideRange(pos: Vector3, weaponInfo: Weapon.WeaponInfo, origin: CFrame): boolean
	local halfRadius = math.rad(weaponInfo.radius / 2 + Params.RADIUS_TOLERANCE)
	local forward = origin.LookVector
	local threshold = math.cos(halfRadius)

	local enemyPos = pos
	local distance = enemyPos - origin.Position

	if distance.Magnitude > weaponInfo.range + Params.DISTANCE_TOLERANCE then
		return false
	end
	local direction = distance.Unit

	local dot = forward:Dot(direction)

	if dot < threshold then
		return false
	end

	return true
end

function WeaponService.HitValidation(self: WeaponService, plr: Player, ids: { string })
	local state = self.PlayerState[plr]
	local weaponData = state.WeaponState.WeaponData()

	if not weaponData or not state.WeaponState.WeaponTool() then
		return
	end

	local lastHit = state.LastHitRequest
	local coolDown = state.WeaponState.CoolDown

	local ping = plr:GetNetworkPing()
	local pingTolerance = math.min(0.3, ping * 3) + Params.JITTER_BUFFER

	local elapsed = time() - lastHit

	local diff = coolDown() - (elapsed + pingTolerance)

	if elapsed + pingTolerance < coolDown() then
		print(`Diff : {diff}, PingTolerance : {pingTolerance}`)
		return
	end

	state.LastHitRequest = time()

	if #ids == 0 or not plr.Character then
		return
	end

	local hrp = plr.Character.PrimaryPart

	if not hrp then
		return
	end

	local globalState = WaveService:GetState(plr)
	if not globalState then
		return
	end

	local posEnemy = globalState:GetEntitiesPos(ids)

	if not posEnemy then
		return
	end
	local weaponInfo = Weapon.NewFromData(weaponData)

	local validIds = {}
	for id, pos in posEnemy do
		if insideRange(pos, weaponInfo, hrp.CFrame) then
			table.insert(validIds, id)
		end
	end

	if #validIds == 0 then
		return
	end

	globalState:ApplyDamage(validIds, weaponInfo.Damage)
end
-- ╔══════════════════════════╗
-- ║  WeaponService : Getter  ║
-- ╚══════════════════════════╝

function WeaponService.GetWeaponState(self: WeaponService, plr: Player): WeaponState
	if not self.PlayerState[plr] then
		self:InitPlr(plr)
	end

	local state = self.PlayerState[plr]

	return state.WeaponState
end

type WeaponState = {
	WeaponData: Charm.Atom<Weapon.MinData?>,
	WeaponTool: Charm.Atom<Tool?>,
	CoolDown: Charm.Atom<number>,
}

type PlayerState = {
	WeaponState: WeaponState,
	LastHitRequest: number,
}
type WeaponService = typeof(WeaponService) & {
	RequestHit: Jolt.Server,
	PlayerState: { [Player]: PlayerState },
	Cleaner: { [Player]: { () -> () } },
}
return WeaponService:Init() :: WeaponService
