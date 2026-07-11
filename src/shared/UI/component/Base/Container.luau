local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props)
	return function(children: { GuiObject })
		local defaultProps = {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = props.BackgroundColor3 and (props.BackgroundTransparency or 0) or 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
			ZIndex = 1,
			Active = false,
			Visible = true,
			Rotation = 0,
		}

		return Vide.create("Frame")(FastProps({
			Props = props,
			Default = defaultProps,
			Children = children,
		}))
	end
end
