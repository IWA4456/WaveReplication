-- ╔══════════════════════╗
-- ║  Modules & Services  ║
-- ╚══════════════════════╝
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PlayerState = require(script.Parent.PlayerState)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Vide = require(ReplicatedStorage.Packages.Vide)
local Enemy = require(ReplicatedStorage.Shared.Info.Enemy)
local LifeBar = require(ReplicatedStorage.Shared.UI.component.Result.LifeBar)
local HoverEnemyConfig = require(ReplicatedStorage.Shared.UI.component.Saddle.HoverEnemy)
local EnemyAnimation = require(ReplicatedStorage.Shared.Utils.EnemyAnimation)

-- ╔══════════╗
-- ║  Player  ║
-- ╚══════════╝
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

--UI
local folderLifeBar = Instance.new("Folder")
folderLifeBar.Parent = gui
local HoverEnemy = HoverEnemyConfig({
	Parent = folderLifeBar,
})

--Model
local enemyModel: { [string]: Model } = ReplicatedStorage.Enemy

--cleaner
local enemyPos: { [string]: Vector3 } = {}
local enemyInfos: { [string]: EnemyInfo } = {}

local enemyCleaner: { [string]: { () -> () } } = {}
local enemyMover: { [string]: () -> () } = {}
local animationTracker: { [string]: { Walk: AnimationTrack, SpeedRatio: number, Death: AnimationTrack } } = {}
local enemyChar: { [string]: Model } = {}

--types
type EnemyInfo = {
	IdInfo: string,
	IdWave: string,
	speed: number,
	Health: Charm.Atom<number>,
}

type WaveInfo = { [string]: string }
-- ╔══════════════╗
-- ║  Initialize  ║
-- ╚══════════════╝
function createEnemyModel(id: string, idWave: string, pos: Vector3): Model
	local wrapper = Instance.new("Model")
	wrapper.Name = idWave

	local model: Model = enemyModel[id]:Clone()

	model:PivotTo(CFrame.new(pos))
	model.Parent = wrapper
	model.Name = idWave
	CollectionService:AddTag(model:FindFirstChild("HumanoidRootPart"), "Enemy")

	enemyChar[idWave] = model

	wrapper.Parent = workspace

	return model, wrapper
end

function WelcomeEnemy(id, health: Charm.Atom<number>)
	local enemyInfo = Enemy.New("Noob")

	local speed = enemyInfo.Speed

	enemyInfos[id] = {
		IdInfo = "Noob",
		speed = speed,
		IdWave = id,
		Health = health,
	}
end

function InitializeEnemy(idWave: string, pos: Vector3)
	local idInfo = enemyInfos[idWave].IdInfo

	local enemyInfo = Enemy.New(idInfo)
	local char, wrapper = createEnemyModel(idInfo, idWave, pos)

	enemyCleaner[idWave] = {
		function()
			wrapper:Destroy()
		end,
	}

	SubscribeToMovement(wrapper, idWave)
	SubscribeToLife(char, idWave, enemyInfo)
	SubscribeToAnimation(char, idWave, enemyInfo)
end

-- ╔═══════════════════════╗
-- ║  Movement Controller  ║
-- ╚═══════════════════════╝
function UpdateMovement(idWave: string, pos: Vector3)
	if not enemyInfos[idWave] then
		return
	end
	local relativeGoalPos = pos
	local corePos = workspace.Target.Position * Vector3.new(1, 0, 1)

	local goalPos = corePos + relativeGoalPos

	if not enemyPos[idWave] then
		InitializeEnemy(idWave, goalPos)
	end
	enemyPos[idWave] = goalPos
end

function SubscribeToMovement(char: Model, idWave: string)
	local _, size = char:GetBoundingBox()

	local height = size.Y / 2

	local con = RunService.RenderStepped:Connect(function(dt)
		Movement(char, idWave, dt, height)
	end)
	enemyMover[idWave] = function()
		con:Disconnect()
	end
end

local HZ = 1 / 15
function Movement(char: Model, idWave: string, dt: number, height: number)
	local goalPos = enemyPos[idWave] + Vector3.yAxis * height

	if not goalPos then
		return
	end
	local corePos = workspace.Target.Position

	local currentPos = char:GetPivot().Position

	local newPos = currentPos:Lerp(goalPos, dt * 15)

	local coreLook = Vector3.new(corePos.X, goalPos.Y, corePos.Z)
	char:PivotTo(CFrame.new(newPos, coreLook))

	--animation speed
	local track = animationTracker[idWave]
	local walk = track.Walk
	local speedRatio = track.SpeedRatio

	local delta = (currentPos - goalPos) * Vector3.new(1, 0, 1)

	local maxSpeed = enemyInfos[idWave].speed

	local speed = math.min(maxSpeed, delta.Magnitude / HZ)

	walk:AdjustSpeed(speed * speedRatio)
end

-- ╔═══════════════════╗
-- ║  Life Controller  ║
-- ╚═══════════════════╝
function KillEnemy(idWave: string, idInfo: string)
	enemyMover[idWave]()

	local trackWalk = animationTracker[idWave].Walk
	trackWalk:Stop(0)

	local hrp: BasePart = PlayerState.hrp()
	local trackDeath = animationTracker[idWave].Death

	local char = enemyChar[idWave]

	local enemyHrp: BasePart = char:FindFirstChild("HumanoidRootPart")
	CollectionService:RemoveTag(enemyHrp, "Enemy")

	EnemyAnimation.DeathAnimation(char, trackDeath, idInfo, hrp).Then(function()
		if enemyCleaner[idWave] then
			for _, cleaner in enemyCleaner[idWave] do
				cleaner()
			end
		end
		enemyCleaner[idWave] = nil
		enemyInfos[idWave] = nil
		enemyPos[idWave] = nil
		animationTracker[idWave] = nil
		enemyMover[idWave] = nil
	end)
end

function SubscribeToLife(enemyCharacter: Model, idWave: string, enemyInfo: Enemy.EnemyInfo)
	local adornee = enemyInfo:GetHover(enemyCharacter)

	local info = enemyInfos[idWave]

	assert(info, "Not initialized")

	local health = info.Health

	local cleaner1 = MountLifeUI(health, adornee, enemyCharacter)

	local dead = false
	local cleaner2 = Charm.effect(function()
		if health() ~= 0 or dead then
			return
		end
		dead = true
		task.spawn(function()
			KillEnemy(idWave, enemyInfo.Id)
		end)
	end)

	table.insert(enemyCleaner[idWave], function()
		cleaner1()
		cleaner2()
	end)
end

function MountLifeUI(health: Charm.Atom<number>, adornee: Instance, enemyCharacter: Model): () -> ()
	local billboard = HoverEnemy(adornee)

	local maxHealth = health()

	local LifeSource = Vide.source(health())

	local damaged = Vide.source(false)

	local cleaner1 = Charm.effect(function()
		if not damaged() then
			task.spawn(function()
				task.wait()
				LifeSource(health())
			end)
		else
			LifeSource(health())
		end
		damaged(health() ~= maxHealth)
	end)

	local cleaner2 = Vide.mount(function()
		return Vide.show(damaged, function()
			return LifeBar({
				LifeSource = LifeSource,
				MaxLife = maxHealth,
				Char = enemyCharacter,
			})
		end)
	end, billboard)

	return function()
		cleaner1()
		cleaner2()
		billboard:Destroy()
	end
end

-- ╔════════════════════════╗
-- ║  Animation Controller  ║
-- ╚════════════════════════╝

function SubscribeToAnimation(enemyChar: Model, idWave: string, enemyInfo: Enemy.EnemyInfo)
	local controller = enemyChar:FindFirstChildWhichIsA("AnimationController")

	assert(controller, "No animation Controller in the char")
	local animator = controller:FindFirstChildWhichIsA("Animator")

	assert(animator, "No animation in the controller")

	local animation = enemyInfo:GetAnimation()

	local trackWalk = animator:LoadAnimation(animation.Walk.Id)
	trackWalk.Looped = animation.Walk.Loop
	trackWalk.Priority = Enum.AnimationPriority.Movement

	local trackDeath = animator:LoadAnimation(animation.Death.Id)
	trackDeath.Looped = false
	trackDeath.Priority = Enum.AnimationPriority.Action4

	-- make attack speed depend on the enemy atack speed

	trackWalk:Play()
	trackWalk.TimePosition = math.random()
	trackWalk:AdjustSpeed(animation.Walk.SpeedRatio * enemyInfo.Speed)

	animationTracker[idWave] = {
		Walk = trackWalk,
		SpeedRatio = animation.Walk.SpeedRatio,
		Death = trackDeath,
		NumberOfHits = animation.Attack.NumberOfHits,
	}
end

return {
	InitializeEnemy = WelcomeEnemy,
	UpdateMovement = UpdateMovement,
}
