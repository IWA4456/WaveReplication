local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	Adornee: BasePart,
})
	local default = {
		Size = UDim2.fromScale(1, 1),
		MaxDistance = 100,
		StudsOffset = Vector3.yAxis,
		AlwaysOnTop = false,
	}

	return Vide.create("BillboardGui")(FastProps({
		Props = props,
		Default = default,
		HardProps = {
			Adornee = props.Adornee,
		},
	}))
end
