local ProceduralBehaviorSchedulerService = game:GetService("ProceduralBehaviorSchedulerService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local DestroyOnClean = require(ReplicatedStorage.Shared.UI.component.Behavior.DestroyOnClean)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local RANDOM_DEGREE = 40
local SIDE = { 1, -1 }

local EFFECT_STATE = {
	Spawning = 1,
	Active = 4,
	Idle = 2,
	Exit = 3,
}

return function(props: Type.Props & {
	Destroy: () -> (),
	Damage: number,
	SizeGoal: UDim2,
})
	local function randomSpawn()
		local xRandom = math.random(2, 8) / 10
		local yRandom = math.random(2, 8) / 10

		return UDim2.fromScale(xRandom, yRandom)
	end

	local function randomGoal(spawnLocation: UDim2)
		local spawnVector = Vector2.new(spawnLocation.X.Scale, spawnLocation.Y.Scale)

		local origin = Vector2.one * 0.5 -- AnchorPoint is 0.5,0.5 by default

		local direction = spawnVector - origin

		local angleDirection = math.atan2(direction.Y, direction.X)

		local offsetAngle = angleDirection + math.rad(math.random(0, RANDOM_DEGREE) * SIDE[math.random(1, 2)])

		local distance = math.random(4, 6) / 10

		local x = math.cos(offsetAngle) * distance
		local y = math.sin(offsetAngle) * distance

		return UDim2.fromScale(spawnLocation.X.Scale + x, spawnLocation.Y.Scale + y)
	end

	local goalSize = Vide.source(UDim2.fromScale(0, 0))
	local goalPosition = Vide.source(randomSpawn())

	local effectState = Vide.source(EFFECT_STATE.Spawning)
	task.defer(function()
		goalSize(props.SizeGoal)
		goalPosition(randomGoal(goalPosition()))
		effectState(EFFECT_STATE.Active)
	end)

	local SizeSmooth = Vide.spring(goalSize, 0.3, 0.4)
	local SizeExit = Vide.spring(goalSize, 0.3, 1)
	local PosSmooth = Vide.spring(goalPosition, 0.6, 0.3)

	local SizeSwitch = Vide.derive(function()
		return effectState() == EFFECT_STATE.Exit and SizeExit() or SizeSmooth()
	end)

	Vide.effect(function()
		local currentPos = PosSmooth()
		local goalPos = goalPosition()
		if effectState() ~= EFFECT_STATE.Active then
			return
		end

		local vectorCurrent = Vector2.new(currentPos.X.Scale, currentPos.Y.Scale)

		local vectorGoal = Vector2.new(goalPos.X.Scale, goalPos.Y.Scale)

		local diff = (vectorCurrent - vectorGoal).Magnitude

		if diff > 0.05 then
			return
		end

		effectState(EFFECT_STATE.Idle)

		task.delay(0.4, function()
			Vide.batch(function()
				effectState(EFFECT_STATE.Exit)
				goalSize(UDim2.fromScale(0, 0))
			end)

			task.wait(0.3)
			props.Destroy()
		end)
	end)

	local Display = Vide.derive(function()
		local digit = props.Damage
		return "-" .. tostring(digit)
	end)

	return TextLabel({
		Size = SizeSwitch,
		Position = PosSmooth,
		Text = Display,
		DestroyOnClean(),
		TextColor3 = Color3.fromHex("#b45b5b"),
	})
end
