local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local HexType = require(ReplicatedStorage.Shared.HexTree.HexType)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local CurrencyDisplay = require(ReplicatedStorage.Shared.UI.component.Base.CurrencyDisplay)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local HoverInfo = require(ReplicatedStorage.Shared.UI.component.Behavior.HoverInfo)
local UICorner = require(ReplicatedStorage.Shared.UI.component.Modifier.UICorner)
local UIHoverZoom = require(ReplicatedStorage.Shared.UI.component.Modifier.UIHoverZoom)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)

local HexColor = {
	["Orange"] = "rbxassetid://111414511270801",
	["Unknown"] = "rbxassetid://104351359411065",
	["NotOwned"] = "rbxassetid://121479387743573",
}

local HexFlatten: { ImageLabel } = {}

for _, asset in HexColor do
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = asset
	table.insert(HexFlatten, imageLabel)
end
if RunService:IsClient() then
	ContentProvider:PreloadAsync(HexFlatten)
end

local RATIO_SIZE = 1.09
local _CONTAINER_SIZE = UDim2.fromScale(0.2, 0.2)

return function(
	props: {
		ImageId: { HexType.HexImage } | HexType.HexImage,
		Color: string,
		Cost: number,
		Position: Vector2,
		ShowSelf: Vide.Source<boolean>,
		ShowNext: Vide.Source<boolean>, --Todo
		Exit: Vide.Source<boolean>,
		OnClick: () -> (),
		Owned: Vide.Source<boolean>,
		PreviousOwned: Vide.Source<boolean>,
		Label: string,
		Description: string,
	}
)
	local pos = props.Position
	local udimPos = UDim2.fromScale(pos.X, pos.Y)

	local sizeGoal = Vide.source(Vector2.zero)

	local sizePopUp = Vide.spring(sizeGoal, 0.4, 0.4)
	local sizeExit = Vide.spring(sizeGoal, 0.2, 1)

	local previousOwnedSaved = props.PreviousOwned()
	local discovered = Vide.source(previousOwnedSaved)

	local sizeUdim = Vide.derive(function()
		local popUp = sizePopUp()
		local exitPop = sizeExit()

		local exit = Vide.untrack(props.Exit)

		if not exit or not discovered() then
			return UDim2.fromScale(exitPop.X, exitPop.Y)
		end

		return UDim2.fromScale(popUp.X, popUp.Y)
	end)

	Vide.effect(function()
		local showSelf = props.ShowSelf()
		local exit = props.Exit()
		local previousOwned = props.PreviousOwned()

		if showSelf and not exit then
			sizeGoal(Vector2.new(0, 0))
			return
		end

		if showSelf then
			sizeGoal(Vector2.new(1, 1))
		else
			sizeGoal(Vector2.new(0, 0))
		end

		if not previousOwned then
			return
		end

		if previousOwned ~= previousOwnedSaved then
			previousOwnedSaved = true
			sizeGoal(Vector2.new(0, 0))
			task.delay(0.2, function()
				sizeGoal(Vector2.new(1, 1))
				task.wait(0.02)
				discovered(true)
				task.wait(0.3)
				props.ShowNext(showSelf)
			end)
			return
		end

		task.delay(0.15, function()
			props.ShowNext(showSelf)
		end)
	end)

	local imageHexagon = Vide.derive(function()
		if not discovered() then
			return HexColor["Unknown"]
		elseif not props.Owned() then
			return HexColor["NotOwned"]
		end
		return HexColor[props.Color]
	end)

	local canClick = Vide.source(false)
	local HexContainer = Container({
		Size = UDim2.fromScale(0.2, 0.2),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Position = udimPos,
		UICorner({
			CornerRadius = UDim.new(1, 0),
		}),
		HoverInfo({
			Header = props.Label,
			Description = props.Description,
			Bottom = function()
				return nil
			end,
			Show = props.PreviousOwned,
			SizeScale = Vector2.new(2, 0.8),
			CanClick = canClick,
		}),
	})
	local HoverContainer = Container({})

	local ContainerPopUp = Container({
		Size = sizeUdim,
	})

	local Ratio = UISizeRatio({
		Ratio = RATIO_SIZE,
	})

	local isHover = Vide.source(false)

	local HoverEffect = UIHoverZoom({
		Intensity = Vector2.new(0.1, 0.1),
		HoverSignal = isHover,
	})

	local TextContainer = Container({
		Size = UDim2.fromScale(0.8, 0.35),
		Position = UDim2.fromScale(0.5, 0.7),
	})

	local ImageLayer: { GuiObject } = {
		Ratio(ImageButton({
			Image = imageHexagon,
			OnClick = function()
				if not isHover() then
					return
				end

				if props.Owned() then
					return
				end
				props.OnClick()
			end,
			ButtonEnabled = canClick,
		})),
		TextContainer({
			TextLabel({
				Text = props.Label,
				Position = UDim2.fromScale(0.5, 0.35),
				Size = UDim2.fromScale(0.8, 0.55),
				Visible = discovered,
			}),
			CurrencyDisplay({
				Currency = Vide.source(props.Cost),
				CurrencyIcon = ImageId.Coin.Id,
				Position = UDim2.fromScale(0.5, 0.8),
				ImageRatio = 0.943,
				ImageSize = UDim2.fromScale(0.4, 0.4),
				Padding = UDim.new(0.05, 0),
				Size = UDim2.fromScale(0.5, 0.5),
				Alignement = Enum.HorizontalAlignment.Center,
				TextSize = UDim2.fromScale(0.4, 0.8),
				Visible = function()
					local discoveredCell = discovered()
					local ownedCell = props.Owned()

					if not discoveredCell then
						return false
					end

					return not ownedCell
				end,
			}),
		}),
	}

	local function insertImageLabel(asset: HexType.HexImage)
		local ratioLayer = asset.Ratio and UISizeRatio({
			Ratio = asset.Ratio,
		}) or function(UI)
			return UI
		end
		local posTable = #ImageLayer
		table.insert(
			ImageLayer,
			posTable,
			ratioLayer(ImageLabel({
				Image = asset.Id,
				Size = asset.Size or UDim2.fromScale(0.6, 0.6),
				Position = asset.Position or UDim2.fromScale(0.5, 0.45),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Visible = discovered,
			}))
		)
	end

	if props.ImageId[1] then
		for _, asset in props.ImageId :: { HexType.HexImage } do
			insertImageLabel(asset)
		end
	else
		insertImageLabel(props.ImageId :: HexType.HexImage)
	end

	return HexContainer({ HoverEffect(HoverContainer({
		ContainerPopUp(ZBatch(1, ImageLayer)),
	})) })
end
