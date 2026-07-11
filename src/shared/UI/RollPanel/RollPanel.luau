local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local CircularPanel = require(ReplicatedStorage.Shared.UI.component.Base.CircularPanel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local CurrencyDisplay = require(ReplicatedStorage.Shared.UI.component.Base.CurrencyDisplay)
local DepthButton = require(ReplicatedStorage.Shared.UI.component.Base.DepthButton)
local Price = require(ReplicatedStorage.Shared.UI.component.Base.Price)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	TargetModel: Model,
	Show: Vide.Source<boolean>,
	OpenSignal: Vide.Source<boolean>,
	Cost: Vide.Source<number>,
	OnClick: () -> (),
	Coins: Vide.Source<number>,
})
	local function Panel(otherProps: Type.Props)
		local propsContainer = Container(otherProps)

		local layout = UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Wraps = false,
			Padding = UDim.new(0.05, 0),
		})

		return propsContainer(layout({
			Price({
				Price = props.Cost,
				Coins = props.Coins,
				Size = UDim2.fromScale(1, 0.5),
			}),
			DepthButton({
				Color = "Green",
				Label = "Roll",
				OnClick = props.OnClick,
				ByPass = true,
				Size = UDim2.fromScale(1, 0.5),
			}),
		}))
	end

	return CircularPanel({
		TargetModel = Vide.source(props.TargetModel),
		Radius = Vide.source(3),
		Show = props.Show,
		OpenSignal = props.OpenSignal,
		Dimension = Vector2.new(5, 3),
		Height = 3,
		Component = Panel,
	})
end
