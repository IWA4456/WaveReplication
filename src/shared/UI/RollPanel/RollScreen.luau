local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RollCoins = require(script.Parent.RollCoins)
local Vide = require(ReplicatedStorage.Packages.Vide)
local Drift = require(ReplicatedStorage.Shared.Drift.Drift)
local HexCoins = require(ReplicatedStorage.Shared.UI.HexUI.HexCoins)
local RollSpin = require(script.Parent.RollSpin)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local DepthButton = require(ReplicatedStorage.Shared.UI.component.Base.DepthButton)
local Price = require(ReplicatedStorage.Shared.UI.component.Base.Price)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	RollItems: Vide.Source<{ string }?>,
	RollIndex: Vide.Source<number>,
	Close: Vide.Source<boolean>,
	OnClick: () -> (),
	Coins: Vide.Source<number>,
	RollPrice: Vide.Source<number>,
})
	local showSpin = Vide.derive(function()
		return props.RollItems() ~= nil
	end)

	local finish = Vide.source(false)

	Vide.effect(function()
		if not props.RollItems() then
			return
		end

		finish(false)
	end)

	local bgContainer = Container({
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		Active = true,
		Vide.show(showSpin, function()
			return RollSpin({
				Size = UDim2.fromScale(0.5, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				RollItems = props.RollItems,
				RollIndex = props.RollIndex,
				Finish = finish,
			})
		end),
		Vide.show(finish, function()
			local RollMenu = Container({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.95),
				Size = UDim2.fromScale(1, 0.1),
			})

			local listLayout = UIListLayout({
				Wraps = false,
				Padding = UDim.new(0.2),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			})

			local rollLayout = UIListLayout({
				Wraps = false,
				Padding = UDim.new(0.02),
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			})

			local sizeGoal = Vide.source(UDim2.fromScale(0, 0))
			local sizeOpen = Drift.Tween(sizeGoal, 0.5, Drift.Easing.backOut)
			local sizeExit = Drift.Tween(sizeGoal, 0.5, Drift.Easing.backIn)

			local sizeTween = Vide.derive(function()
				if finish() == false then
					return sizeExit()
				end

				return sizeOpen()
			end)

			sizeGoal(UDim2.fromScale(1, 1))

			Vide.effect(function()
				if finish() == false then
					sizeGoal(UDim2.fromScale(0, 0))
				end
			end)

			local closeContainer = Container({
				Size = UDim2.fromScale(0.2, 1),
			})

			local rollContainer = Container({
				Size = UDim2.fromScale(0.2, 2),
				rollLayout({}),
			})

			local rollSize = Vide.derive(function()
				local vec = Vector2.new(sizeTween().X.Scale, sizeTween().Y.Scale)

				vec *= Vector2.new(1, 0.5)

				return UDim2.fromScale(vec.X, vec.Y)
			end)

			return RollMenu(listLayout({
				rollContainer({
					Price({
						Size = rollSize,
						Price = props.RollPrice,
						Coins = props.Coins,
					}),
					DepthButton({
						Color = "Green",
						Label = "Roll",
						OnClick = function()
							if not finish() then
								return
							end
							props.OnClick()
						end,
						Size = rollSize,
					}),
				}),
				closeContainer({
					DepthButton({
						Color = "Red",
						Label = "Close",
						OnClick = function()
							if not finish() then
								return
							end
							props.Close(false)
						end,
						Size = sizeTween,
					}),
				}),
			})),
				0.6
		end),
		Vide.show(finish, function()
			local sizeGoal = Vide.source(UDim2.fromScale(0, 0))
			local sizeOpen = Drift.Tween(sizeGoal, 0.5, Drift.Easing.backOut)
			local sizeExit = Drift.Tween(sizeGoal, 0.5, Drift.Easing.backIn)

			local sizeTween = Vide.derive(function()
				if finish() == false then
					return sizeExit()
				end

				return sizeOpen()
			end)

			sizeGoal(UDim2.fromScale(1, 1))

			Vide.effect(function()
				if finish() == false then
					sizeGoal(UDim2.fromScale(0, 0))
				end
			end)

			local coinContainer = Container({
				Position = UDim2.fromScale(0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromScale(0.2, 0.1),
			})

			return coinContainer({
				RollCoins({
					Coins = props.Coins,
					Size = sizeTween,
				}),
			}), 0.6
		end),
	})

	return bgContainer({})
end
