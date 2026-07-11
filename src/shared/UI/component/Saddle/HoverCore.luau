local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
return function(props: {
	Parent: Folder,
})
	return function(Core: Model)
		local cf, size = Core:GetBoundingBox()

		local topPos = cf.Position + Vector3.new(0, size.Y / 2, 0)

		local adornee = Core.PrimaryPart

		local offset = topPos - adornee.Position + Vector3.yAxis * 2

		offset *= Vector3.yAxis * 1.1

		return Vide.create("BillboardGui")({
			Parent = props.Parent,
			Size = UDim2.fromScale(5 * 1.5, 1.3 * 1.5),
			MaxDistance = 100,
			StudsOffset = offset,
			Adornee = adornee,
		})
	end
end
