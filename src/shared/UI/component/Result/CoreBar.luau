local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Bar = require(ReplicatedStorage.Shared.UI.component.Base.Bar)

local Type = require(ReplicatedStorage.Shared.UI.component.Type)
type Props = Type.Props

return function(props: {
	LifeSource: Vide.Source<number>,
	MaxLife: number,
})
	local smoothDigit = Vide.spring(props.LifeSource, 1, 0.8)

	local Display = Vide.derive(function()
		local digit = math.round(math.clamp(smoothDigit(), 0, props.MaxLife))
		return digit .. "/" .. props.MaxLife
	end)

	return Bar({
		BottomColor = Color3.fromHex("#ffffff"),
		TopColor = Color3.fromHex("#00a2ff"),
		Max = props.MaxLife,
		Source = props.LifeSource,
		Shake = true,
		Display = Display,
	})
end
