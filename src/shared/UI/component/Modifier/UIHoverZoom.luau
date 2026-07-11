local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)

return function(props: {
	Intensity: Vector2,
	MobileExcluded: boolean?,
	HoverSignal: Vide.Source<boolean>?,
})
	return function(target: GuiObject)
		if props.MobileExcluded and UserInputService.TouchEnabled then
			return target
		end

		local originalSize = target.Size
		local vectorSize = Vector2.new(originalSize.X.Scale, originalSize.Y.Scale)

		local targetSize = Vide.source(vectorSize)

		local Size = Vide.spring(targetSize, 0.3, 0.8)

		Vide.cleanup(target.MouseEnter:Connect(function()
			targetSize(vectorSize + props.Intensity)
			if props.HoverSignal then
				props.HoverSignal(true)
			end
		end))

		Vide.cleanup(target.MouseLeave:Connect(function()
			targetSize(vectorSize)
			if props.HoverSignal then
				props.HoverSignal(false)
			end
		end))

		Vide.effect(function()
			local udimSize = UDim2.fromScale(Size().X, Size().Y)
			target.Size = udimSize
		end)

		return target
	end
end
