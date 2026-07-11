local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

return function(props: Type.Props & {
	Currency: Vide.Source<number>,
	CurrencyIcon: string,
	ImageRatio: number?,
	ImageSize: UDim2?,
	Padding: UDim?,
	Alignement: Enum.HorizontalAlignment?,
	TextSize: UDim2?,
	Visible: Type.value<boolean>?,
	TextColor: Type.value<Color3>?,
})
	local CurrencyContainer = Container({
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Visible = props.Visible or true,
	})

	local ListLayout = UIListLayout({
		Padding = props.Padding or UDim.new(0, 10),
		HorizontalAlignment = props.Alignement or Enum.HorizontalAlignment.Left,
		Wraps = false,
	})

	local Ratio = UISizeRatio({
		Ratio = props.ImageRatio or 1,
	})

	local currencyFormat = Vide.derive(function()
		return FormatNumber(props.Currency())
	end)

	return CurrencyContainer(ListLayout({
		Ratio(ImageLabel({
			Image = props.CurrencyIcon,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = props.ImageSize or UDim2.fromScale(0.5, 1.2),
		})),
		TextLabel({
			Text = currencyFormat,
			Size = props.TextSize or UDim2.fromScale(0.5, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = props.TextColor,
		}),
	}))
end
