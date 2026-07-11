local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientFlow = require(script.Parent.StateFlow.ClientFlow)
local Charm = require(ReplicatedStorage.Packages.Charm)
local DeepEqualizer = require(ReplicatedStorage.Shared.DeepEqualizer)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local Jolt = require(ReplicatedStorage.Shared.Jolt.Jolt)
local PlayerState = require(script.Parent.PlayerState)
local WeaponClient = {}
function WeaponClient:Init()
	self:Build()
end

function WeaponClient.Build(self: WeaponClient)
	self.WeaponData = ClientFlow:GetAsync("WeaponData")

	self.WeaponInfo = Charm.computed(function(prev: Weapon.WeaponMeta?)
		local info = Weapon.NewFromData(self.WeaponData())

		if prev and DeepEqualizer(prev, info) then
			return prev
		end

		return info
	end)

	self.CoolDown = ClientFlow:GetAsync("CoolDown")

	self.AnimationIndex = Charm.atom(1)

	self.Animation = Charm.computed(function()
		local info = self.WeaponInfo()

		return info:GetAnimation()[self.AnimationIndex()]
	end)

	self.RequestHit = Jolt.Client("RequestHit")

	self:InitWeapon()

	self.AttackTime = Charm.atom(0)
	--self.AttackStreak = ClientFlow:GetAsync("AttackStreak")
	return self
end

function WeaponClient.InitWeapon(self: WeaponClient)
	self.WeaponTool = ClientFlow:GetAsync("WeaponTool")

	Charm.effect(function()
		local tool = self.WeaponTool()
		if not tool then
			return
		end

		if self.HitConnection then
			self.HitConnection:Disconnect()
			self.HitConnection = nil
		end

		self.HitConnection = tool.Activated:Connect(function()
			self:Click()
		end)
	end)
end

function WeaponClient.Click(self: WeaponClient)
	local info = self.WeaponInfo()

	if not info then
		return
	end

	if time() - self.AttackTime() < self.CoolDown() then
		return
	end

	self:PlayAnimation(function()
		local enemies = self:DetectEnemy()

		if not enemies then
			return
		end

		self.RequestHit:Fire(enemies)
	end)

	self.AttackTime(time())
end

function WeaponClient.PlayAnimation(self: WeaponClient, callback: () -> ())
	local info = self.WeaponInfo()

	if not info then
		return
	end

	local animation = self.Animation()
	local nextIndex = info:GetNextAnimationIndex(self.AnimationIndex())
	self.AnimationIndex(nextIndex)

	local animator: Animator = PlayerState.animator()

	if not animator then
		return
	end

	local track = animator:LoadAnimation(animation)
	if track.Length == 0 then
		return
	end
	track:Play()

	local speed = track.Length / info.Duration
	track:AdjustSpeed(speed)

	local conn: RBXScriptConnection? = nil

	conn = track:GetMarkerReachedSignal("Hit"):Once(function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		callback()
	end)

	task.delay(info.Duration * 2, function()
		if conn then
			conn:Disconnect()
		end
	end)

	return track
end

function WeaponClient.DetectEnemy(self: WeaponClient): { string }?
	local hrp: BasePart = PlayerState.hrp()
	local weaponInfo = self.WeaponInfo()

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

	return validEnemies
end

function WeaponClient.AttackOnDetect(self: WeaponClient)
	local info = self.WeaponInfo()

	if not info then
		return
	end
	if time() - self.AttackTime() < self.CoolDown() then
		return
	end

	local enemies = self:DetectEnemy()

	if not enemies then
		return
	end

	local track = self:PlayAnimation(function()
		local currentEnemies = self:DetectEnemy()

		if not currentEnemies then
			return
		end

		self.RequestHit:Fire(currentEnemies)
	end)

	if not track then
		return
	end

	self.AttackTime(time())
end

type WeaponClient = typeof(WeaponClient) & {
	WeaponInfo: Charm.Atom<Weapon.WeaponMeta>,
	WeaponData: Charm.Atom<Weapon.MinData>,
	AttackTime: Charm.Atom<number>,
	WeaponTool: Charm.Atom<Tool?>,
	CoolDown: Charm.Atom<number>,
	Animation: Charm.Atom<Animation>,
	AnimationIndex: Charm.Atom<number>,
	RequestHit: Jolt.Client,
	HitConnection: RBXScriptConnection?,
}

return WeaponClient:Init() :: WeaponClient
