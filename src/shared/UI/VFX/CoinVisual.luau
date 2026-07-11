local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
return function()
	local adornee = Instance.new("Part")
	adornee.Size = Vector3.one
	adornee.Anchored = true
	adornee.CanCollide = false
	adornee.Transparency = 1
	adornee.Parent = game.Workspace

	local attach0 = Instance.new("Attachment")
	local attach1 = Instance.new("Attachment")

	attach0.Parent = adornee
	attach1.Parent = adornee

	local trail = Instance.new("Trail")
	trail.Texture = ImageId.ItemTrail.Id
	trail.TextureMode = "Stretch"
	trail.Color = ColorSequence.new(Color3.new(1, 0.733333, 0))
	trail.LightEmission = 0.25
	trail.Parent = adornee
	trail.Attachment0 = attach0
	trail.Attachment1 = attach1
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Lifetime = 0.3
	trail.FaceCamera = true

	attach1.CFrame = CFrame.new(0, 2, 0)
	attach0.CFrame = CFrame.new(0, 1, 0)

	return adornee
end
