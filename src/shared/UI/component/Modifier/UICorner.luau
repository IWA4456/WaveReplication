local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

return function(props: Type.Props & {
	CornerRadius: UDim?,
})
	return Vide.create("UICorner")({
		CornerRadius = props.CornerRadius or UDim.new(0.08, 0),
	})
end
