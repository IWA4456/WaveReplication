local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

return function(props: {
	StrokeColor: Color3?,
	Thickness: number?,
	Transparency: number?,
	ApplyStrokeMode: Enum.ApplyStrokeMode?,
	LineJoinMode: Enum.LineJoinMode?,
})
	return Vide.create("UIStroke")({
		Color = props.StrokeColor or Color3.fromHex("#000000"),
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		Thickness = props.Thickness or 0.1,
		Transparency = props.Transparency or 0,
		ApplyStrokeMode = props.ApplyStrokeMode or Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = props.LineJoinMode or Enum.LineJoinMode.Bevel,
	})
end
