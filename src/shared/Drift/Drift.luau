local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Track = require(script.Parent.Track)
local Ripple = require(ReplicatedStorage.Packages.Ripple)
local Vide = require(ReplicatedStorage.Packages.Vide)

local createTween = Ripple.createTween
local Drift = {}
Drift.Easing = {
	backIn = "backIn",
	backInOut = "backInOut",
	backOut = "backOut",
	bounceIn = "bounceIn",
	bounceInOut = "bounceInOut",
	bounceOut = "bounceOut",
	circIn = "circIn",
	circInOut = "circInOut",
	circOut = "circOut",
	cubicIn = "cubicIn",
	cubicInOut = "cubicInOut",
	cubicOut = "cubicOut",
	elasticIn = "elasticIn",
	elasticInOut = "elasticInOut",
	elasticOut = "elasticOut",
	expoIn = "expoIn",
	expoInOut = "expoInOut",
	expoOut = "expoOut",
	instant = "instant",
	linear = "linear",
	quadIn = "quadIn",
	quadInOut = "quadInOut",
	quadOut = "quadOut",
	quartIn = "quartIn",
	quartInOut = "quartInOut",
	quartOut = "quartOut",
	quintIn = "quintIn",
	quintInOut = "quintInOut",
	quintOut = "quintOut",
	sineIn = "sineIn",
	sineInOut = "sineInOut",
	sineOut = "sineOut",
	smoothstep = "smoothstep",
}

function Drift.Tween<value>(
	source: Vide.Source<value>,
	duration: number,
	style: Ripple.Easing
): (Vide.Source<value>, Ripple.Tween<value>)
	local tween: Ripple.Tween<value> = createTween(source(), {
		duration = duration,
		easing = style,
		start = true,
	})

	local result = Vide.source(source())

	tween:onChange(function(value, _deltaTime: number)
		result(value)
	end)

	Vide.effect(function()
		tween:setGoal(source())
	end)

	Vide.cleanup(function()
		tween:destroy()
	end)

	return result, tween
end

function Drift.FortuneWheel(goal: Vide.Source<number>, duration: number, callback: () -> ()): Vide.Source<number>
	local track = Track(goal)

	local startDuration = duration * 0.1
	local point2Duration = duration * 0.7
	local point3Duration = duration * 0.1
	local endDuration = duration * 0.1

	track:AddStart(
		createTween(goal(), {
			easing = Drift.Easing.cubicOut,
			duration = startDuration,
			start = true,
		}),
		{
			Relative = "Origin",
			Offset = -1,
		}
	)
	track:AddPoint(
		createTween(0, {
			easing = Drift.Easing.quadInOut,
			duration = point2Duration,
			start = true,
		}),
		Vide.derive(function()
			return goal() + 0.2
		end)
	)

	track:AddPoint(
		createTween(0, {
			easing = Drift.Easing.sineInOut,
			duration = point3Duration,
			start = true,
		}),
		Vide.derive(function()
			return goal() - 0.1
		end)
	)

	track:AddEnd(createTween(0, {
		easing = Drift.Easing.sineInOut,
		duration = endDuration,
		start = true,
	}))

	track:OnComplete(callback)

	return track.Result
end

type Drift = typeof(Drift)

return Drift :: Drift
