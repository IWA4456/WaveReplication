-- ╔══════════════════════╗
-- ║  Modules & Services  ║
-- ╚══════════════════════╝

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AttackInterface = require(script.Parent.Parent.HUD.AttackInterface)
local AtomData = require(script.Parent.Parent.AtomData)
local PlayerState = require(script.Parent.Parent.PlayerState)
local Charm = require(ReplicatedStorage.Packages.Charm)
local DeepEqualizer = require(ReplicatedStorage.Shared.DeepEqualizer)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)

--events
local WeaponSync = Jolt.Client("WeaponSync")
local RequestHit = Jolt.Client("RequestHit")

--Activation connection
local activationConnection: RBXScriptConnection? = nil

-- ╔═════════╗
-- ║  Atoms  ║
-- ╚═════════╝
local weaponAtom: Charm.Atom<Weapon.WeaponMeta?> = Charm.computed(function()
	local weaponData = AtomData.Weapons()[AtomData.EquipedWeapon()]
	if not weaponData then
		return nil
	end
	return Weapon.NewFromData(weaponData)
end, {
	equals = DeepEqualizer,
})

local attackTime = Charm.atom(0)

-- ╔════════════════════╗
-- ║  Detection System  ║
-- ╚════════════════════╝

local function DetectEnemy(passive: boolean?): { string }?
	local hrp: BasePart = PlayerState.hrp()
	local weaponInfo = weaponAtom()

	if not weaponInfo or not hrp then
		return nil
	end

	local halfRadius = math.rad(weaponInfo.radius / 2)
	local forward = hrp.CFrame.LookVector
	local threshold = math.cos(halfRadius)

	local validEnemies = {}

	for _, enemy: BasePart & { Parent: Model } in CollectionService:GetTagged("Enemy") do
		local enemyPos = enemy.Position
		local distance = enemyPos - hrp.Position

		if distance.Magnitude > weaponInfo.range then
			continue
		end
		local direction = distance.Unit

		local dot = forward:Dot(direction)

		if dot < threshold then
			continue
		end

		local idWave = enemy.Parent.Name
		table.insert(validEnemies, idWave)
	end

	if #validEnemies == 0 then
		return nil
	end

	if passive then
		return validEnemies
	end
	RequestHit:Fire(validEnemies)
	return validEnemies
end

-- ╔════════════════════════════════╗
-- ║  WeaponController : Animation  ║
-- ╚════════════════════════════════╝

local currentIndex = 1

local function AttackAnimation(callback: (boolean) -> any): AnimationTrack?
	local weaponInfo = weaponAtom()

	if not weaponInfo then
		return
	end

	local animationId = weaponInfo:GetAnimation()[currentIndex]
	currentIndex = weaponInfo:GetNextAnimationIndex(currentIndex)

	local animator = PlayerState.animator()
	if not animator then
		return
	end

	local track: AnimationTrack = animator:LoadAnimation(animationId)
	if track.Length == 0 then
		return
	end
	track:Play()

	local speed = track.Length / weaponInfo.Duration
	track:AdjustSpeed(speed)

	track:GetMarkerReachedSignal("Hit"):Once(function()
		callback(false)
	end)

	return track
end

-- ╔══════════════════════════════════╗
-- ║  WeaponController : Auto-Attack  ║
-- ╚══════════════════════════════════╝

local function AutoAttack()
	local weaponInfo = weaponAtom()
	if not weaponInfo then
		return
	end

	local cooldown = weaponInfo.CoolDown + weaponInfo.Duration

	if time() - attackTime() < cooldown then
		return
	end

	local enemies = DetectEnemy(true)

	if not enemies then
		return
	end

	AttackInterface:ResetAttackState()

	if not AttackAnimation(DetectEnemy) then
		return
	end
	attackTime(time())
end

local conn: RBXScriptConnection

Charm.effect(function()
	local autoAttackEnabled = AtomData.AutoAttack()

	if conn then
		conn:Disconnect()
	end

	if autoAttackEnabled then
		conn = RunService.RenderStepped:Connect(AutoAttack)
	end
end)

-- ╔══════════════╗
-- ║  ClickEvent  ║
-- ╚══════════════╝
local function clickWeapon()
	local weaponInfo = weaponAtom()

	local cooldown = weaponInfo.CoolDown + weaponInfo.Duration
	if time() - attackTime() < cooldown or not weaponInfo then
		return
	end
	local track = AttackAnimation(DetectEnemy)

	if not track then
		return
	end

	attackTime(time())
end

-- ╔══════════════════╗
-- ║  Initialization  ║
-- ╚══════════════════╝
local function connectNewWeapon(weaponServer: Tool?)
	if activationConnection then
		activationConnection:Disconnect()
	end
	local weapon: Tool = weaponServer or PlayerState.plr.Backpack:FindFirstChild(AtomData.EquipedWeapon())
	activationConnection = weapon.Activated:Connect(clickWeapon)
end

WeaponSync:Connect(connectNewWeapon)

WeaponSync:Fire()
return weaponAtom
