local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ripple = require(ReplicatedStorage.Packages.Ripple)
local Vide = require(ReplicatedStorage.Packages.Vide)
local Track = {}
Track.__index = Track

function New(goal: Vide.Source<number>): Track
	local self = setmetatable({}, Track)
	self.Goal = goal
	self.Waypoint = {} :: { Ripple.Tween<number> }
	self.Current = Vide.source(0)
	self.Result = Vide.source(0)
	self.Complete = {} :: { () -> () }
	self.Origin = Vide.source(0)
	return self
end

function Track.AddStart(
	self: Track,
	tween: Ripple.Tween<number>,
	params: {
		Relative: "Origin" | "Goal",
		Offset: number,
		Fraction: boolean?,
	}?
)
	local index = #self.Waypoint + 1

	self.Waypoint[index] = tween

	self.Origin(self.Goal())
	self.Result(self.Goal())

	Vide.effect(function()
		local result = self.Result()
		local current = self.Current()
		if current ~= index then
			self.Origin(result)
		end
	end)

	local goal = Vide.derive(function()
		if not params then
			return self.Goal()
		end
		local diff = self.Goal() - self.Origin()
		local offset = params.Fraction and diff * params.Offset or params.Offset

		if params.Relative == "Origin" then
			return self.Origin() + offset
		else
			return self.Goal() + offset
		end
	end)

	Vide.effect(function()
		local tweenGoal = goal()

		if self.Current() ~= index then
			tween:stop()
			return
		end

		tween:start()
		tween:setGoal(tweenGoal)
	end)
	Vide.effect(function()
		tween:setPosition(self.Origin())
	end)

	tween:onChange(function(value: number, _deltaTime: number)
		if self.Current() ~= index then
			return
		end
		self.Result(value)
	end)

	tween:onComplete(function(value: number)
		local next = self.Waypoint[index + 1]
		assert(next, "There is no second waypoint in the track")
		next:setPosition(value)
		self.Current(index + 1)
	end)

	Vide.cleanup(function()
		tween:destroy()
	end)
end

function Track.AddPoint(self: Track, tween: Ripple.Tween<number>, goal: Vide.Source<number>)
	local index = #self.Waypoint + 1

	if index == 1 then
		error("You need a start before adding a Point")
	end

	self.Waypoint[index] = tween

	Vide.effect(function()
		if self.Current() ~= index then
			tween:stop()
			return
		end
		tween:setGoal(goal())
		tween:start()
	end)

	tween:onChange(function(value, _deltaTime: number)
		if self.Current() ~= index then
			return
		end
		self.Result(value)
	end)

	tween:onComplete(function(value: number)
		local nextIndex = index + 1
		assert(self.Waypoint[nextIndex], `The waypoint {nextIndex} is Nil !`)

		self.Waypoint[nextIndex]:setPosition(value)
		self.Current(nextIndex)
	end)

	Vide.cleanup(function()
		tween:destroy()
	end)
end

function Track.AddEnd(self: Track, tween: Ripple.Tween<number>)
	local index = #self.Waypoint + 1

	if index == 1 then
		error("A Track need a start before getting an end !")
	end

	self.Waypoint[index] = tween

	Vide.effect(function()
		if self.Current() ~= index then
			tween:stop()
			return
		end

		tween:setGoal(self.Goal())
		tween:start()
	end)

	tween:onChange(function(value, _deltaTime: number)
		if self.Current() ~= index then
			return
		end
		self.Result(value)
	end)

	tween:onComplete(function(_value: number)
		for _, callback in self.Complete do
			callback()
		end
		self.Current(0)
	end)

	Vide.cleanup(function()
		tween:destroy()
	end)
	local init = false
	Vide.effect(function()
		self.Goal()
		if not init then
			init = true
			return
		end
		self.Current(1)
	end)
end

function Track.OnComplete(self: Track, callback: () -> ())
	table.insert(self.Complete, callback)
end

type Track = typeof(New(Vide.source(1)))

return New
