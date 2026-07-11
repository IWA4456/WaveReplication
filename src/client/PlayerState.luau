local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local State = {}

State.plr = Players.LocalPlayer :: Player

-- ╔════════╗
-- ║  Atom  ║
-- ╚════════╝

State.char = Charm.atom(State.plr.Character or State.plr.CharacterAdded:Wait()) :: Charm.Atom<Model>

State.humanoid = Charm.atom(State.char():FindFirstChildWhichIsA("Humanoid")) :: Charm.Atom<Humanoid?>

State.animator = Charm.atom(nil) :: Charm.Atom<Animator?> | Charm.Atom<nil>

State.hrp = Charm.atom(nil) :: Charm.Atom<BasePart?> | Charm.Atom<nil>

State.charHeight = Charm.computed(function()
	local humanoid = State.humanoid()
	local hrp = State.hrp()
	if not hrp or not humanoid then
		return nil
	end
	return (humanoid.HipHeight + hrp.Size.Y / 2) * 2
end) :: Charm.Atom<number>

-- ╔════════════════╗
-- ║  Update State  ║
-- ╚════════════════╝
local subscribed: { () -> () } = {}
local function onDied()
	State.char(nil)
	State.char(State.plr.CharacterAdded:Wait())

	for _, callback in subscribed do
		callback()
	end
end

Charm.effect(function()
	if not State.char() then
		return
	end
	local char = State.char()
	State.humanoid(char:FindFirstChildWhichIsA("Humanoid"))
	State.hrp(char:FindFirstChild("HumanoidRootPart"))

	local humanoid = State.humanoid()
	if not humanoid then
		task.spawn(function()
			local hum = char:WaitForChild("Humanoid")
			State.humanoid(hum)
			State.animator(hum:FindFirstChildWhichIsA("Animator"))
		end)
	else
		State.animator(humanoid:FindFirstChildWhichIsA("Animator"))
	end

	if not State.hrp() then
		task.spawn(function()
			local hrp = char:WaitForChild("HumanoidRootPart")
			State.hrp(hrp)
		end)
	end

	task.defer(function()
		local hum = State.humanoid()
		assert(hum, "The humanoid is not loaded")
		hum.Died:Once(onDied)
	end)
end)

-- ╔═════════════╗
-- ║  Subscribe  ║
-- ╚═════════════╝

function State.SubscribeToCharacterAdded(callback: () -> ())
	table.insert(subscribed, callback)
end

return State
