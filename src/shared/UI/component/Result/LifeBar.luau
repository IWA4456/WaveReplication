local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageEffect = require(script.Parent.DamageEffect)
local Vide = require(ReplicatedStorage.Packages.Vide)
local SoundAsset = require(ReplicatedStorage.Shared.Asset.SoundAsset)
local Bar = require(ReplicatedStorage.Shared.UI.component.Base.Bar)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)

local Type = require(ReplicatedStorage.Shared.UI.component.Type)
type Props = Type.Props

local plr = Players.LocalPlayer

local function VisualEffect(char: Model)
	local partSaddle = Instance.new("Part")

	partSaddle.CanCollide = false
	partSaddle.Anchored = true
	partSaddle.Transparency = 1
	partSaddle.Name = "VisualEffect"
	partSaddle.Size = Vector3.one

	local emitter = ReplicatedStorage.VFX.HitMark:Clone()

	emitter.Parent = partSaddle

	partSaddle.Parent = workspace

	Vide.cleanup(partSaddle)

	return function() -- emit
		local plrChar = plr.Character

		if not plrChar then
			return
		end

		local hrp = plrChar.PrimaryPart

		if not hrp then
			return
		end

		local cf, size = char:GetBoundingBox()
		local objectPos = cf:PointToObjectSpace(hrp.Position)

		local direction = objectPos.Unit

		local halfSize = size / 2

		local tX = math.huge
		local tZ = math.huge

		if direction.X ~= 0 then
			tX = halfSize.X / math.abs(direction.X)
		end

		if direction.Z ~= 0 then
			tZ = halfSize.Z / math.abs(direction.Z)
		end

		local t = math.min(tX, tZ)

		local localEffectPos = direction * t

		local worldEffectPos = cf:PointToWorldSpace(localEffectPos)

		partSaddle.Position = worldEffectPos

		emitter:Emit(1)
	end
end

return function(props: {
	LifeSource: Vide.Source<number>,
	MaxLife: number,
	Char: Model,
})
	local smoothDigit = Vide.spring(props.LifeSource, 0.6, 0.8)

	local Display = Vide.derive(function()
		local digit = math.round(math.max(0, smoothDigit()))
		return digit .. "/" .. props.MaxLife
	end)

	local damageDelta: Vide.Source<{ { Damage: number } }> = Vide.source({})

	local previousLife = props.LifeSource()

	local damageTime = Vide.source(0)

	local soundEffect = Instance.new("Sound")

	soundEffect.SoundId = SoundAsset.HitSound.Id
	soundEffect.Parent = props.Char
	soundEffect.Volume = 0.05
	soundEffect.RollOffMaxDistance = 50

	Vide.cleanup(soundEffect)

	local emitter = VisualEffect(props.Char)

	Vide.effect(function()
		local currentLife = props.LifeSource()

		local delta = math.ceil(previousLife - currentLife)

		if delta == 0 then
			return
		end

		soundEffect:Play()
		soundEffect.TimePosition = SoundAsset.HitSound.Start ---+ --(math.random(0, 10) - 5) / 500

		emitter()

		previousLife = currentLife

		local damageClone = table.clone(damageDelta())

		damageTime(damageTime() + 1)

		table.insert(damageClone, { Damage = delta })

		damageDelta(damageClone)
	end)

	local BarContainer = Container({
		Vide.values(damageDelta, function(delta, index)
			return DamageEffect({
				Damage = delta.Damage,
				SizeGoal = UDim2.fromScale(0.9, 0.9),
				Destroy = function()
					local damageClone = table.clone(damageDelta())

					table.remove(damageClone, index())

					damageDelta(damageClone)
				end,
			})
		end),
		Size = UDim2.fromScale(0.30, 0.30),
	})

	local transparencyGoal = Vide.source(1)

	Vide.effect(function()
		local idCurrent = damageTime()

		if idCurrent == 0 then
			return
		end

		task.spawn(function()
			transparencyGoal(0.4)
			task.wait(0.2)
			if idCurrent ~= damageTime() then
				return
			end

			transparencyGoal(1)
		end)
	end)

	local HLight: Highlight = Instance.new("Highlight")
	HLight.OutlineTransparency = 1
	HLight.FillColor = Color3.fromHex("#d10000")

	HLight.Parent = props.Char

	Vide.cleanup(HLight)

	local FillSpring = Vide.spring(transparencyGoal, 0.2, 1)

	Vide.effect(function()
		HLight.FillTransparency = FillSpring()
	end)

	return BarContainer({
		Bar({
			BottomColor = Color3.fromHex("#FF0000"),
			TopColor = Color3.fromHex("#04FF00"),
			Max = props.MaxLife,
			Source = props.LifeSource,
			Shake = true,
			Display = Display,
		}),
	})
end
