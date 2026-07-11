local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	Streak: Vide.Source<number>,
	ActiveStreak: Vide.Source<boolean>,
})
	local topReached = 0
	local streakGoal = Vide.derive(function()
		local activeStreak = props.ActiveStreak()
		local streak = props.Streak()

		if activeStreak then
			if streak ~= 0 then
				topReached = streak
			end
			return streak
		end

		return 0
	end)
	local smoothDigit = Vide.spring(streakGoal, 0.7, 1)
	local streakDigit = Vide.derive(function()
		local rounded = math.ceil(smoothDigit())

		return math.clamp(rounded, 0, topReached)
	end)

	local sizeGoal = Vide.source(UDim2.fromScale(0, 0))
	local sizeSpring = Vide.spring(sizeGoal, 0.5, 0.4)
	local sizeExit = Vide.spring(sizeGoal, 0.5, 1)

	local size = Vide.derive(function()
		local active = props.ActiveStreak()
		local spring = sizeSpring()
		local exit = sizeExit()

		if active then
			return spring
		end

		return exit
	end)

	local init = false
	Vide.effect(function()
		if props.ActiveStreak() then
			sizeGoal(UDim2.fromScale(1, 1))
			init = true
			return
		end
		if not init then
			return
		end

		sizeGoal(UDim2.fromScale(1.3, 1.3))

		task.delay(0.4, function()
			sizeGoal(UDim2.fromScale(0, 0))
		end)
	end)

	local SpringContainer = Container({
		Size = size,
	})

	local flameGoal = Vide.source(UDim2.fromScale(1, 1))
	local flamePulse = Vide.spring(flameGoal, 0.2, 0.8)

	local FlameContainer = Container(props)

	Vide.effect(function()
		local streak = props.Streak()

		if streak == 0 then
			return
		end

		flameGoal(UDim2.fromScale(1.1, 1.1))

		task.delay(0.2, function()
			flameGoal(UDim2.fromScale(1, 1))
		end)
	end)

	local PulseContainer = Container({
		Size = flamePulse,
	})

	local flame = ImageId.Flame
	local FlameRatio = UISizeRatio({
		Ratio = flame.Ratio,
	})

	return FlameContainer({
		SpringContainer({
			PulseContainer(ZBatch(5, {
				FlameRatio(ImageLabel({
					Image = flame.Id,
					Size = flamePulse,
				})),
				TextLabel({
					Text = streakDigit,
					Size = UDim2.fromScale(0.4, 0.4),
					Position = UDim2.fromScale(0.5, 0.7),
				}),
			})),
		}),
	})
end
