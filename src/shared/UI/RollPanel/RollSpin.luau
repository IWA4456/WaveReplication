local DebuggerManager = game:GetService("DebuggerManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ripple = require(ReplicatedStorage.Packages.Ripple)
local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local Drift = require(ReplicatedStorage.Shared.Drift.Drift)
local RarityColor = require(ReplicatedStorage.Shared.Enums.RarityColor)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local UIStroke = require(ReplicatedStorage.Shared.UI.component.Modifier.UIStroke)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local function parabola(x: number): number
	return math.clamp(4 * x * (1 - x), 0, 1)
end

local function translate(x: number, min: number, max: number): number
	return (x - min) / (max - min)
end

return function(props: Type.Props & {
	RollItems: Vide.Source<{ string }>,
	RollIndex: Vide.Source<number>,
	Finish: Vide.Source<boolean>,
})
	local propsContainer = Container(props)

	local ratioContainer = Container({})

	local ratio = UISizeRatio({
		Ratio = 1 / 2,
	})

	local listLayout = UIListLayout({
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
		Wraps = false,
	})

	local rotGoal = Vide.source(0)
	local rotSpring, rotControls = Vide.spring(rotGoal, 0.5, 0.7)
	local rotLeft, leftControls = Vide.spring(rotGoal, 0.5, 0.7)

	local selectorGoal = Vide.source(0.1)
	local selectorPos = Drift.Tween(selectorGoal, 0.5, Drift.Easing.backInOut)

	local selectedIndex = Vide.source(0)

	local SelectorColor = Vide.derive(function()
		local index = selectedIndex()

		if index < 1 then
			return Color3.fromHex("#ffffff")
		end

		local id = props.RollItems()[index]

		local info = Weapon.New(id)

		return RarityColor[info.Rarity]
	end)

	local function Selector(otherProps: {
		Side: "Right" | "Left",
	})
		local ratioSelector = UISizeRatio({
			Ratio = ImageId.LightSword.Ratio,
		})

		local selectorContainer = Container({
			Size = UDim2.fromScale(0.4, 1),
		})

		local selectorRotation = Vide.derive(function()
			if otherProps.Side == "Right" then
				return rotSpring()
			end

			return rotLeft() + 180
		end)

		return selectorContainer({
			ratioSelector(ImageLabel({
				Image = ImageId.LightSword.Id,
				Rotation = selectorRotation,
				Position = Vide.derive(function()
					local offset = otherProps.Side == "Right" and -selectorPos() or selectorPos()

					return UDim2.fromScale(0.5 + offset, 0.5)
				end),
				ImageColor3 = SelectorColor,
			})),
		})
	end

	local WheelState = {
		Rolling = 1,
		Idle = 2,
	}

	local RollState = Vide.source(WheelState.Rolling)

	local SizeGoal = Vide.source(UDim2.fromScale(1, 1))
	local tweenSize = Drift.Tween(SizeGoal, 0.3, Drift.Easing.quadIn)

	local TargetGoal = Vide.source(0.5)
	local TargetPos = Drift.FortuneWheel(TargetGoal, 5, function()
		RollState(WheelState.Idle)
	end)

	local spinStar = Vide.source(0)

	local speed = 40

	Vide.cleanup(RunService.RenderStepped:Connect(function(dt)
		if RollState() ~= WheelState.Idle then
			return
		end

		spinStar(spinStar() + speed * dt)
	end))

	local lastImpulse = TargetGoal() + 0.5
	Vide.effect(function()
		local diff = TargetPos() - lastImpulse

		if WheelState.Idle == RollState() then
			diff = 0
			lastImpulse = 1
			return
		end

		if math.abs(diff) >= 1 then
			lastImpulse += 1 * math.sign(diff)

			local direction = math.sign(diff)
			rotControls({
				impulse = -350 * direction,
			})
			leftControls({
				impulse = 350 * direction,
			})
		end
	end)

	local function WheelPos(index: number): Vide.Source<Vector2>
		return Vide.derive(function()
			local offsetFactor = index - 3

			local GoalPos = Vector2.new(0.5, TargetPos() - offsetFactor)

			if GoalPos.Y >= 0 and GoalPos.Y <= 1 then
				selectedIndex(index)
			end

			return GoalPos
		end)
	end

	local function ItemSize(index: number, pos: Vide.Source<Vector2>): Vide.Source<UDim2>
		return Vide.derive(function()
			local t = translate(pos().Y, -1.3, 2.3)

			local size = parabola(t)

			if index ~= props.RollIndex() or RollState() == WheelState.Rolling then
				return UDim2.fromScale(size, size)
			end

			return tweenSize()
		end)
	end

	local function ItemsWheel()
		local displayContainer = Container({
			Size = UDim2.fromScale(0.6, 0.33),
			Vide.indexes(props.RollItems, function(id: () -> string, index: number)
				local info = Vide.derive(function()
					return Weapon.New(id())
				end)

				local image = Vide.derive(function()
					return info():GetImage()
				end)

				local name = Vide.derive(function()
					return info().Name
				end)

				local posVector = WheelPos(index)

				local pos = Vide.derive(function()
					return UDim2.fromScale(posVector().X, posVector().Y)
				end)

				local size = ItemSize(index, posVector)

				local WeaponContainer = Container({
					Size = ItemSize(index, posVector),
					Position = pos,
					ZIndex = Vide.derive(function()
						if index ~= props.RollIndex() then
							return 5
						end
						return 10
					end),
				})

				local ImageRatio = UISizeRatio({
					Ratio = function()
						return image().Ratio
					end,
				})

				local starRatio = UISizeRatio({
					Ratio = 1,
				})

				local textSize = Vide.derive(function()
					local y = size().Y.Scale

					return y * 25
				end)

				local transparency = Vide.derive(function()
					local y = posVector().Y

					local t = translate(y, -1.5, 2.5)

					return 1 - parabola(t)
				end)

				return WeaponContainer(ZBatch(2, {
					starRatio(ImageLabel({
						Image = ImageId.Star.Id,
						ImageColor3 = function()
							return RarityColor[info().Rarity]
						end,
						Rotation = function()
							if index == props.RollIndex() then
								return spinStar()
							end

							return 0
						end,
						ImageTransparency = transparency,
					})),
					ImageRatio(ImageLabel({
						Image = function()
							return image().Id
						end,
						ImageTransparency = transparency,
					})),
					TextLabel({
						Text = name,
						Size = UDim2.fromScale(1, 0.3),
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, 1),
						TextSize = textSize,
						TextWrapped = false,
						TextTransparency = transparency,
					}),
				}))
			end),
		})

		return displayContainer({})
	end

	Vide.effect(function()
		if RollState() == WheelState.Rolling then
			return
		end

		task.delay(0.8, function()
			if RollState() == WheelState.Idle then
				props.Finish(true)
			end
		end)
	end)

	local items = props.RollItems()
	Vide.effect(function()
		if items == props.RollItems() then
			return
		end

		RollState(WheelState.Rolling)
	end)

	Vide.effect(function()
		if RollState() == WheelState.Idle then
			SizeGoal(UDim2.fromScale(1.35, 1.35))
			selectorGoal(-0.3)
			return
		end
		TargetPos(0.5)
		TargetGoal(0.5)
		TargetGoal(props.RollIndex() - 2.5)
		SizeGoal(UDim2.fromScale(1, 1))
		spinStar(0)
		selectorGoal(0.1)
	end)

	return propsContainer({
		ratio(ratioContainer(listLayout({
			Selector({ Side = "Left" }),
			ItemsWheel(),
			Selector({ Side = "Right" }),
		}))),
	})
end
