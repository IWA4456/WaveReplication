local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
return function(props: {
	Parent: Folder,
})
	return function(adornee: Instance)
		return Vide.create("BillboardGui")({
			Parent = props.Parent,
			Size = UDim2.fromScale(5 * 2, 1.3 * 2),
			MaxDistance = 50,
			StudsOffset = Vector3.new(0, 2, 0),
			Adornee = adornee,
		})
	end
end
