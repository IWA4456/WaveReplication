local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

export type AssetImage = {
	Id: string,
	Ratio: number?,
}

local asset = {
	LifeBubble = {
		Id = "rbxassetid://123397954345754",
	},
	Coin = {
		Id = "rbxassetid://123610903762984",
	},
	ItemTrail = {
		Id = "rbxassetid://2316283203",
	},
	UpgradeArrow = {
		Id = "rbxassetid://97663470155834",
	},
	Sword = {
		Id = "rbxassetid://136850213312605",
		Ratio = 1,
	},
	RedoArrow = {
		Id = "rbxassetid://73854265440411",
		Ratio = 340 / 382,
	},
	Flame = {
		Id = "rbxassetid://112458896933002",
		Ratio = 254 / 362,
	},
	HoverBack = {
		Id = "rbxassetid://116528692976523",
	},
	Dice = {
		Id = "rbxassetid://73166498782616",
		Ratio = 587 / 640,
	},
	--Inventory
	SwordTitle = {
		Id = "rbxassetid://86907814183615",
		Ratio = 1124 / 301,
	},
	ExitInventory = {
		Id = "rbxassetid://115151551385507",
		Ratio = 222 / 229,
	},
	BackPack = {
		Id = "rbxassetid://131986734799465",
		Ratio = 359 / 405,
	},
	InventoryBackground = {
		Id = "rbxassetid://123709655259771",
		Ratio = 1432 / 828,
	},
	Equipped = {
		Id = "rbxassetid://107001787801571",
		Ratio = 225 / 98,
	},
	LightSword = { Id = "rbxassetid://87134926551052", Ratio = 404 / 176 },
	Star = {
		Id = "rbxassetid://134536225033499",
		Ratio = 1,
	},
}

local WeaponImage = {
	WoodenSword = {
		Id = "rbxassetid://72224363257290",
		Ratio = 354 / 486,
	},
	WoodenBat = {
		Id = "rbxassetid://138516649902472",
		Ratio = 294 / 424,
	},
}

local combinedAsset = {}

if RunService:IsServer() then
	return asset
end

local preloadAsset = {}

for key, assetContent in asset do
	combinedAsset[key] = assetContent

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = assetContent.Id

	table.insert(preloadAsset, imageLabel)
end

for key, assetWeapon in WeaponImage do
	combinedAsset[key] = assetWeapon

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = assetWeapon.Id

	table.insert(preloadAsset, imageLabel)
end

ContentProvider:PreloadAsync(preloadAsset)

for _, instance in preloadAsset do
	instance:Destroy()
end

return combinedAsset :: typeof(asset) & typeof(WeaponImage)
