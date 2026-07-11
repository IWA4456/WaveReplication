local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FireStreak = require(script.Parent.FireStreak)
local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local UIHoverZoom = require(ReplicatedStorage.Shared.UI.component.Modifier.UIHoverZoom)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	OnClick: () -> (),
	Enabled: Vide.Source<boolean>,
	AttackState: Vide.Source<number>,
	Streak: Vide.Source<number>,
	ActiveStreak: Vide.Source<boolean>,
})
	local activeGoal = Vide.source(UDim2.fromScale(0, 0))

	Vide.effect(function()
		local enabled = props.Enabled()

		if enabled then
			activeGoal(UDim2.fromScale(0.5, 0.95))
		else
			activeGoal(UDim2.fromScale(0.5, 1.12))
		end
	end)

	local activePosition = Vide.spring(activeGoal, 1, 0.4)

	local attackContainer = Container({
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(1, 1),
	})

	local displayContainer = Container({
		Size = UDim2.fromScale(1.5, 1.5),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = activePosition,
	})

	local RatioButton = UISizeRatio({})

	local RatioArrow = UISizeRatio({
		Ratio = 340 / 382,
	})

	local HoverEffect = UIHoverZoom({
		Intensity = Vector2.one * 0.1,
	})

	local rotationGoal = Vide.source(0)
	local rotationSpring = Vide.spring(rotationGoal, 1, 0.8)

	local openDone = Vide.source(props.Enabled())

	local rotation = Vide.derive(function()
		local spring = rotationSpring()

		if openDone() then
			return rotationGoal()
		end

		return spring
	end)

	local sizeGoal = Vide.source(Vector2.new(0, 0))

	local sizeSpring = Vide.spring(sizeGoal, 0.6, 0.6)

	local size = Vide.derive(function()
		return UDim2.fromScale(sizeSpring().X, sizeSpring().Y)
	end)
	local velocity = 0

	Vide.effect(function()
		local enabled = props.Enabled()

		if enabled then
			sizeGoal(Vector2.new(1, 1))
			rotationGoal(0)
			task.delay(1.5, function()
				if props.Enabled() then
					openDone(true)
				end
			end)
		else
			sizeGoal(Vector2.new(0, 0))
			openDone(false)
			rotationGoal(360)
			velocity = 0
		end
	end)

	local speed = 20 -- degree per sec
	local speedActive = 200

	local acceleration = 35

	Vide.cleanup(RunService.RenderStepped:Connect(function(dt: number)
		--TODO
		if not openDone() then
			return
		end

		local IsActive = props.AttackState() > time()

		local goalSpeed = IsActive and speedActive or speed

		local direction = math.sign(goalSpeed - velocity)

		velocity = velocity + acceleration * dt * direction

		rotationGoal(rotationGoal() - velocity * dt)

		velocity = math.min(velocity, speedActive)

		if rotationGoal() < -360 then
			rotationGoal(0)
		end
	end))

	return attackContainer({
		HoverEffect(displayContainer(ZBatch(1, {
			RatioArrow(ImageLabel({
				Image = ImageId.RedoArrow.Id,
				AnchorPoint = Vector2.new(0.5, 0.445),
				Position = UDim2.fromScale(0.5, 0.445),
				Rotation = rotation,
				Size = size,
			})),
			RatioButton(ImageButton({
				Image = ImageId.Sword.Id,
				OnClick = props.OnClick,
				Size = UDim2.fromScale(0.67, 0.67),
				Position = UDim2.fromScale(0.5, 0.55),
			})),
			FireStreak({
				Position = UDim2.fromScale(0.2, 0.2),
				Size = UDim2.fromScale(0.55, 0.55),
				Streak = props.Streak,
				ActiveStreak = props.ActiveStreak,
			}),
		}))),
	})
end
