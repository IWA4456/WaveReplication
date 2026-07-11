local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
type Props = Type.Props

return function(props: Props)
	local Modifier = props.Modifier or {}

	return function(children: { GuiObject })
		local childrenMod = table.clone(children)
		for _, mod in Modifier do
			table.insert(childrenMod, Vide.create(mod)({}))
		end
		return Vide.create("CanvasGroup")({
			Size = props.Size or UDim2.fromScale(1, 1),
			Position = props.Position or UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = props.BackgroundColor3 or Color3.new(1, 1, 1),
			BackgroundTransparency = props.BackgroundTransparency or 1,
			AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
			table.unpack(childrenMod),
		})
	end
end
