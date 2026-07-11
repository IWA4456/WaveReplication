local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local SurfaceGui = require(ReplicatedStorage.Shared.UI.Primitive.SurfaceGui)
local DepthButton = require(ReplicatedStorage.Shared.UI.component.Base.DepthButton)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local plr = Players.LocalPlayer

local PanelParams = {
	Height = 4,
}

return function(props: Type.Props & {
	CoreModel: Vide.Source<Model?>,
	Radius: Vide.Source<number>,
	OnClick: () -> (),
	SelfShow: Vide.Source<boolean>,
	OpenSignal: Vide.Source<boolean>,
})
	local coreCenter = Vide.derive(function()
		if not props.CoreModel() then
			return Vector3.zero
		end

		local cf = props.CoreModel():GetBoundingBox()
		return (cf.Position * Vector3.new(1, 0, 1)) :: Vector3
	end)

	local coreBottom = Vide.derive(function()
		if not props.CoreModel() then
			return 0
		end

		local cf, size = props.CoreModel():GetBoundingBox()
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
		local char = plr.Character
		local hrp = char and char.PrimaryPart or nil

		if not char or not hrp then
			return
		end

		local distance = (hrp.Position * Vector3.new(1, 0, 1) - coreCenter()).Magnitude

		if distance <= props.Radius() - 2 then
			return
		end

		local lookdir = ((hrp.Position - coreCenter()) * Vector3.new(1, 0, 1)).Unit

		lookDirection(lookdir)

		-- Shortest path
		local delta = ((angle() - currentAngle() + 180) % 360) - 180

		-- Distance de freinage : v²/2a
		local brakingDistance = (velocity * velocity) / (2 * acceleration)

		if math.abs(delta) > brakingDistance then
			-- Encore loin : accélère vers le goal
			velocity += acceleration * dt * math.sign(delta)
		else
			-- Zone de freinage : décélère
			velocity -= brakeForce * dt * math.sign(velocity)
		end

		velocity = math.clamp(velocity, -speed, speed)

		currentAngle(currentAngle() + velocity * dt)
	end))

	local adornee = Instance.new("Part")

	adornee.Name = "CorePanel"

	adornee.CanCollide = false
	adornee.Anchored = true
	adornee.Transparency = 1

	adornee.Size = Vector3.new(6, 2, 0.5)

	adornee.Parent = workspace

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
			props.SelfShow(false)
		end)
		closing = true
	end)

	Vide.effect(function()
		local current = math.rad(currentAngle())

		local look = Vector3.new(math.cos(current), 0, math.sin(current))

		local offset = look * (props.Radius() - 0.5)

		local corePos = coreCenter() * Vector3.new(1, 0, 1)
			+ coreBottom() * Vector3.yAxis
			+ Vector3.yAxis * PanelParams.Height

		local pos = corePos + offset

		adornee.CFrame = CFrame.new(pos, pos + look + Vector3.yAxis * 0.7)
	end)

	return SurfaceGui({
		Adornee = adornee,
		DepthButton({
			Color = "Green",
			Label = "Start",
			OnClick = props.OnClick,
			ByPass = true,
			Size = sizeExit,
		}),
	})
end
