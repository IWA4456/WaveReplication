local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local SurfaceGui = require(ReplicatedStorage.Shared.UI.Primitive.SurfaceGui)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local plr = Players.LocalPlayer

return function(props: Type.Props & {
	TargetModel: Vide.Source<Model>,
	Radius: Vide.Source<number>,
	Show: Vide.Source<boolean>,
	OpenSignal: Vide.Source<boolean>,
	Component: (Type.Props) -> GuiObject,
	Dimension: Vector2,
	Height: number,
})
	local targetCF = Vide.source(props.TargetModel():GetBoundingBox())

	local center = Vide.derive(function()
		local cf = targetCF()
		return (cf.Position * Vector3.new(1, 0, 1)) :: Vector3
	end)

	local bottom = Vide.derive(function()
		local _, size = props.TargetModel():GetBoundingBox()
		local cf = targetCF()

		return (cf.Position.Y - size.Y / 2) :: number
	end)

	local lookDirection = Vide.source(Vector3.zero)

	local angle = Vide.derive(function()
		return math.deg(math.atan2(lookDirection().Z, lookDirection().X))
	end)

	local speed = 150
	local acceleration = 100
	local velocity = 0
	local brakeForce = 80
	local currentAngle = Vide.source(angle())
	Vide.cleanup(RunService.RenderStepped:Connect(function(dt)
		targetCF(props.TargetModel():GetBoundingBox())

		local char = plr.Character
		local hrp = char and char.PrimaryPart or nil

		if not char and not hrp then
			return
		end

		local distance = (hrp.Position * Vector3.new(1, 0, 1) - center()).Magnitude

		if distance <= props.Radius() - 2 then
			return
		end

		local lookdir = ((hrp.Position - center()) * Vector3.new(1, 0, 1)).Unit

		lookDirection(lookdir)

		local delta = ((angle() - currentAngle() + 180) % 360) - 180

		local brakingDistance = (velocity * velocity) / (2 * acceleration)

		if math.abs(delta) > brakingDistance then
			velocity += acceleration * dt * math.sign(delta)
		else
			velocity -= brakeForce * dt * math.sign(velocity)
		end

		velocity = math.clamp(velocity, -speed, speed)

		currentAngle(currentAngle() + velocity * dt)
	end))

	local adornee = Instance.new("Part")

	adornee.Name = `{props.TargetModel().Name}_Panel`

	adornee.CanCollide = false
	adornee.Anchored = true
	adornee.Transparency = 1

	adornee.Size = Vector3.new(props.Dimension.X, props.Dimension.Y, 0.5)

	adornee.Parent = props.TargetModel().Parent

	Vide.cleanup(adornee)

	local sizeGoal = Vide.source(UDim2.fromScale(1, 1))

	local sizeExit = Vide.spring(sizeGoal, 0.3, 1)

	local closing = false
	Vide.effect(function()
		if props.OpenSignal() or closing then
			return
		end
		sizeGoal(UDim2.fromScale(1.3, 1.3))
		task.delay(0.4, function()
			sizeGoal(UDim2.fromScale(0, 0))
			task.wait(1)
			props.Show(false)
		end)
		closing = true
	end)

	Vide.effect(function()
		local current = math.rad(currentAngle())

		local look = Vector3.new(math.cos(current), 0, math.sin(current))

		local offset = look * (props.Radius() - 0.5)

		local corePos = center() + bottom() * Vector3.yAxis + Vector3.yAxis * props.Height

		local pos = corePos + offset

		adornee.CFrame = CFrame.new(pos, pos + look + Vector3.yAxis * 0.7)
	end)

	return SurfaceGui({
		Adornee = adornee,
		props.Component({
			Size = sizeExit,
		}),
	})
end
