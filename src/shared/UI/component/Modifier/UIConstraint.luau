local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	MaxSize: Vector2?,
	MinSize: Vector2?,
})
	return Vide.create("UISizeConstraint")(FastProps({
		Props = props,
		Default = {
			MaxSize = Vector2.new(100, 100),
			MinSize = Vector2.zero,
		},
	}))
end
