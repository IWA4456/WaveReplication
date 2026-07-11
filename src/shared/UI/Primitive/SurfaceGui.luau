local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	MaxDistance: number?,
	ResetOnSpawn: boolean?,
	PixelsPerStuds: number?,
	Adornee: BasePart,
})
	local default = {
		MaxDistance = 100,
		ResetOnSpawn = false,
		PixelsPerStud = 50,
		LightInfluence = 0,
	}

	return Vide.create("SurfaceGui")(FastProps({
		Props = props,
		Default = default,
		HardProps = {
			Adornee = props.Adornee,
		},
	}))
end
