local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HexCoins = require(script.Parent.HexCoins)
local Vide = require(ReplicatedStorage.Packages.Vide)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local DepthButton = require(ReplicatedStorage.Shared.UI.component.Base.DepthButton)
local UIConstraint = require(ReplicatedStorage.Shared.UI.component.Modifier.UIConstraint)

return function(props: {
	Leave: () -> (),
	Coins: Vide.Source<number>,
})
	local background = Container({
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Active = true,
	})

	local FakeGUI = Container({})({
		background({}),
	})

	return FakeGUI,
		function()
			local button = DepthButton({
				Color = "Red",
				Label = "CLOSE",
				Position = UDim2.fromScale(0.5, 0.97),
				AnchorPoint = Vector2.new(0.5, 1),
				OnClick = props.Leave,
				Size = UDim2.fromScale(0.2, 0.11),
				UIConstraint({
					MinSize = Vector2.new(50, 25),
					MaxSize = Vector2.new(200, 100),
				}),
			})

			local coinsDisplay: GuiObject = HexCoins({
				Coins = props.Coins,
			})

			coinsDisplay.Parent = FakeGUI
			coinsDisplay.ZIndex = 11
			button.Parent = FakeGUI
			button.ZIndex = 10

			Vide.cleanup(button)
			Vide.cleanup(coinsDisplay)
		end
end
