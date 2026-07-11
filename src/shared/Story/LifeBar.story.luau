local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local LifeBar = require(ReplicatedStorage.Shared.UI.component.Result.LifeBar)

local controls = {
	LifeSource = 10,
}

return {
	vide = Vide,
	controls = controls,
	story = function(props)
		return LifeBar({
			LifeSource = props.controls.LifeSource,
			MaxLife = props.controls.LifeSource(),
		})
	end,
}
