local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

return function(props: {
	FillDirection: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	SortOrder: Enum.SortOrder?,
	VerticalAlignment: Enum.VerticalAlignment?,
	Padding: UDim?,
	Wraps: boolean?,
})
	return function(children: { GuiObject }): { GuiObject }
		local content = {
			Vide.create("UIListLayout")({
				FillDirection = props.FillDirection or Enum.FillDirection.Horizontal,
				HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Center,
				SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder,
				VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Center,
				Padding = props.Padding or UDim.new(0, 0),
				Wraps = props.Wraps == nil and true or props.Wraps,
			}),
		}

		for _, child in children do
			table.insert(content, child)
		end

		return content
	end
end
