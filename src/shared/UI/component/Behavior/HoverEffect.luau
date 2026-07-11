local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
return function(props: {
	TargetParent: boolean?,
	Intensity: Vector2?,
})
	return Vide.action(function(target: GuiObject)
		local intensity = props.Intensity or Vector2.one * 0.1

		local function hoverEffect(realTarget)
			local originalSize = realTarget.Size
			local vectorSize = Vector2.new(originalSize.X.Scale, originalSize.Y.Scale)

			local targetSize = Vide.source(vectorSize)
			local spring = Vide.spring(targetSize, 0.3, 0.8)

			Vide.cleanup(target.MouseEnter:Connect(function()
				targetSize(vectorSize + intensity)
			end))

			Vide.cleanup(target.MouseLeave:Connect(function()
				targetSize(vectorSize)
			end))

			Vide.effect(function()
				local udimSize = UDim2.fromScale(spring().X, spring().Y)
				realTarget.Size = udimSize
			end)
		end

		if props.TargetParent then
			local destroy: () -> ()

			task.defer(function()
				destroy = Vide.root(function()
					local parent = target.Parent

					if not parent then
						print("No Parent")
					end

					hoverEffect(parent)
				end)
			end)

			Vide.cleanup(function()
				task.spawn(function()
					if not destroy then
						task.wait()
					end
					destroy()
				end)
			end)

			return
		end

		hoverEffect(target)
	end)
end
