local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Bezier = require(ReplicatedStorage.Shared.Bezier.Bezier)
local CoinVisual = require(ReplicatedStorage.Shared.UI.VFX.CoinVisual)
local DestroyOnClean = require(ReplicatedStorage.Shared.UI.component.Behavior.DestroyOnClean)
local CoinsItems = require(ReplicatedStorage.Shared.UI.component.Result.CoinsItems)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	Coins: Vide.Source<number>,
	Adornee: Model,
	Target: BasePart,
	Destroy: () -> (),
	Parent: Folder,
	Sound: { Play: (any) -> (), [string]: any },
})
	local adornee = CoinVisual()
	adornee.CFrame = props.Adornee:GetPivot()

	Vide.cleanup(adornee)

	local midPoint = adornee.CFrame:Lerp(props.Target.CFrame, -0.3) * CFrame.new(math.random(-10, 10), 10, 0)

	local function sigmoid(t: number, k: number): number
		return 1 / (1 + math.exp(-k * (t - 0.5)))
	end

	local function sigmoidNormalized(t: number, k: number): number
		local s0 = sigmoid(0, k)
		local s1 = sigmoid(1, k)
		return (sigmoid(t, k) - s0) / (s1 - s0)
	end

	local curve = Bezier.new({
		adornee.Position,
		midPoint.Position,
		props.Target.Position,
	})

	Vide.cleanup(function()
		curve:Destroy()
	end)

	curve:UpdateLUT()

	local duration = 0.7
	local startTime = time()

	local goalReached = Vide.source(false)

	local conn = RunService.RenderStepped:Connect(function()
		local elapsed = time() - startTime
		local tRaw = math.clamp(elapsed / duration, 0, 1)
		local t = sigmoidNormalized(tRaw, 12)

		local currentTarget = props.Target.Position
		curve.Points[3] = currentTarget

		local pos = curve:DeCasteljau(t)
		adornee.Position = pos

		if t >= 1 and not goalReached() then
			task.spawn(function()
				goalReached(true)
				props.Sound:Play()
				task.wait(0.2)
				props.Destroy()
			end)
		end
	end)

	Vide.cleanup(conn)

	local bill = Vide.create("BillboardGui")({
		Adornee = adornee,
		Size = props.Size or UDim2.fromScale(1.7, 1.7),
		MaxDistance = 200,
		StudsOffset = Vector3.new(0, 1, 0),
		Parent = props.Parent,
		AlwaysOnTop = true,
		DestroyOnClean(),
		CoinsItems({
			Coins = props.Coins,
			Vide.action(function(UI: Instance)
				Vide.effect(function()
					if not goalReached() then
						return
					end
					UI:Destroy()
				end)
			end),
		}),
	})

	return bill
end
