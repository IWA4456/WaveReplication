local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Enemy = require(ReplicatedStorage.Shared.Info.Enemy)

local FLYING_DISTANCE = 4
function DeathAnimation(enemy: Model, trackDeath: AnimationTrack, idInfo: string, hrp: BasePart)
	local animation = Enemy.New(idInfo):GetAnimation()
	local Events = animation.Death.Events

	local EnemyHrp = enemy:GetPivot()

	trackDeath:Play()

	local direction = ((EnemyHrp.Position - hrp.Position) * Vector3.new(1, 0, 1)).Unit

	local impactTime = trackDeath:GetTimeOfKeyframe(Events[2])

	local lookAt = Vector3.new(hrp.Position.X, enemy:GetPivot().Position.Y, hrp.Position.Z)

	enemy:PivotTo(CFrame.new(enemy:GetPivot().Position, lookAt))

	local vanished = false

	task.spawn(function()
		trackDeath:GetMarkerReachedSignal(Events[1]):Wait()
		local currentTime = trackDeath.TimePosition

		local deltaTime = impactTime - currentTime
		local speed = FLYING_DISTANCE / deltaTime

		local hrpPos = hrp.Position

		local conn = RunService.renderStepped:Connect(function(dt)
			local currentPos = enemy:GetPivot().Position
			local newPos =
				CFrame.new(currentPos + direction * speed * dt, Vector3.new(hrpPos.X, currentPos.Y, hrpPos.Z))
			enemy:PivotTo(newPos)
		end)

		trackDeath:GetMarkerReachedSignal(Events[2]):Wait()
		conn:Disconnect()

		trackDeath:GetMarkerReachedSignal(Events[3]):Wait()

		trackDeath:AdjustSpeed(0)

		task.wait(2) -- Make the corpse disappear
		vanished = true
	end)

	return {
		Then = function(callback: () -> ()): number
			task.spawn(function()
				while not vanished do
					task.wait()
				end
				callback()
			end)
			return impactTime
		end,
	}
end

return {
	DeathAnimation = DeathAnimation,
}
