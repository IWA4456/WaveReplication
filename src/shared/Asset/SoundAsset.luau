local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local soundAsset = {
	HitSound = {
		Id = "rbxassetid://103397225855135",
		Start = 0.155,
	},
	CollectCoins1 = {
		Id = "rbxassetid://607662191",
		Volume = 0.1,
		Start = 0.1,
	},
	CollectCoins2 = {
		Id = "rbxassetid://607665037",
		Volume = 0.1,
		Start = 0.1,
	},
	CollectCoins3 = {
		Id = "rbxassetid://99927446005550",
		Volume = 0.3,
		Start = 0.1,
	},
	Swing = {
		Id = "rbxassetid://137387991353521",
	},
}

if RunService:IsServer() then
	return soundAsset
end

local preloadInstance = {}

for _, info in soundAsset do
	local instance = Instance.new("Sound")
	instance.SoundId = info.Id
	table.insert(preloadInstance, instance)
end

ContentProvider:PreloadAsync(preloadInstance)

for _, instance in preloadInstance do
	instance:Destroy()
end

return soundAsset
