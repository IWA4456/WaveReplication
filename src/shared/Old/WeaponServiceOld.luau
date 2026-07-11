-- ╔══════════════════════╗
-- ║  Modules & Services  ║
-- ╚══════════════════════╝
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local DataManager = require(ServerScriptService.Data.DataManager)
local StateFlow = require(ServerScriptService.Game.StateFlow.StateFlow)
local EnemyState = require(ServerScriptService.Game.WaveService.EnemyState)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)

-- events
local WeaponSync = Jolt.Server("WeaponSync")
local RequestHit = Jolt.Server("RequestHit")
--Player data
local PlayerWeapon: { [Player]: Charm.Atom<Weapon.WeaponData> } = {}
local PlayerStreak: { [Player]: Charm.Atom<number> } = {}

local BroomerProfile: { [Player]: { () -> () } } = {}

-- ╔══════════╗
-- ║  Attack  ║
-- ╚══════════╝
local TOLERANCE = 1
local TOLERANCE_RADIUS = 10
local function insideRange(pos: Vector3, weaponInfo: Weapon.WeaponInfo, origin: CFrame): boolean
	local halfRadius = math.rad(weaponInfo.radius / 2 + TOLERANCE_RADIUS)
	local forward = origin.LookVector
	local threshold = math.cos(halfRadius)

	local enemyPos = pos
	local distance = enemyPos - origin.Position

	if distance.Magnitude > weaponInfo.range + TOLERANCE then
		return false
	end
	local direction = distance.Unit

	local dot = forward:Dot(direction)

	if dot < threshold then
		return false
	end

	return true
end

local function handleHitRequest(player: Player, ids: { string })
	--Todo: handle spam
	if #ids == 0 or not player.Character then
		return
	end

	local hrp = player.Character.PrimaryPart

	if not hrp then
		return
	end

	local globalState = EnemyState(player)

	if not globalState then
		return
	end

	local weaponData = PlayerWeapon[player]()
	local weaponInfo = Weapon.NewFromData(weaponData)

	local posEnemy = globalState:GetEnemyPos(ids)

	if not posEnemy then
		return
	end

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

RequestHit:Connect(handleHitRequest)
-- ╔══════════════════╗
-- ║  Initialization  ║
-- ╚══════════════════╝
local function deepEqualizer(prev: Weapon.WeaponData, next: Weapon.WeaponData): boolean
	for key, value in next do
		if type(value) == "table" then
			if not deepEqualizer(prev[key], value) then
				return false
			end
		elseif prev[key] ~= value then
			return false
		end
	end

	return true
end

function EquipWeapon(plr: Player, weaponData: Weapon.WeaponData)
	local weaponInfo = Weapon.NewFromData(weaponData)
	local tool = weaponInfo:GetTool()
	tool.Name = weaponData.IdInventory

	local char = plr.Character or plr.CharacterAdded:Wait()

	if char:FindFirstChildWhichIsA("Tool") then
		char:FindFirstChildWhichIsA("Tool"):Destroy()
	end

	tool.Parent = char
	print(tool)
	WeaponSync:Fire(plr, tool)
end

function InitializePlr(player: Player)
	if PlayerWeapon[player] then
		return
	end

	local Profile = DataManager.GetProfile(player, true)

	if not Profile then
		return
	end

	--atoms
	local equipedWeaponId = Profile.EquipedWeapon
	local weaponInventoryId = Profile.Weapons

	local weaponData = Charm.computed(function()
		return weaponInventoryId()[equipedWeaponId()]
	end, {
		equals = deepEqualizer,
	})

	local function equipNew()
		if equipedWeaponId() == "" then
			return
		end
		task.spawn(function()
			EquipWeapon(player, Charm.peek(weaponData))
		end)
	end

	local cleaner1 = Charm.effect(equipNew)

	local cleaner2 = player.CharacterAdded:Connect(equipNew)

	PlayerWeapon[player] = weaponData
	BroomerProfile[player] = {
		function()
			cleaner1()
			cleaner2:Disconnect()
		end,
	}

	--PlayerStreak

	PlayerStreak[player] = Charm.atom(0)

	StateFlow:Register(player, {
		AttackStreak = PlayerStreak[player],
	})
end

function CleanPlr(player: Player)
	if BroomerProfile[player] then
		for _, cleaner: () -> () in BroomerProfile[player] do
			cleaner()
		end
	end
	BroomerProfile[player] = nil
	PlayerWeapon[player] = nil
	PlayerStreak[player] = nil
end

Players.PlayerRemoving:Connect(CleanPlr)
WeaponSync:Connect(InitializePlr)

return PlayerWeapon
