local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DestroyOnClean = require(script.Parent.DestroyOnClean)
local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

local screenHover = Instance.new("ScreenGui")
screenHover.Name = "HoverInfo"
screenHover.DisplayOrder = 10

if RunService:IsRunning() then
	local plr = Players.LocalPlayer

	local plrUI = plr.PlayerGui
	screenHover.Parent = plrUI
end

local activeHover = Vide.source(nil)

local Params = {
	SizeRatio = 0.07,
}

return function(props: Type.Props & {
	Header: string,
	Description: string,
	Bottom: () -> (),
	Show: Vide.Source<boolean>,
	SizeScale: Vector2?,
	CanClick: Vide.Source<boolean>?,
})
	local positionHover = Vide.source(UDim2.fromOffset(0, 0))
	local sizeHover = Vide.source(UDim2.fromOffset(0, 0))

	local HoverContainer = Container(FastProps({
		Props = props,
		Default = props,
		HardProps = {
			Position = positionHover,
			Size = sizeHover,
			DestroyOnClean(),
			AnchorPoint = Vector2.new(0, 0.5),
		},
	}))

	local TextContainer = Container({
		Size = UDim2.fromScale(1, 1),
	})
	local Layout = UIListLayout({
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 0),
	})

	local textSize = Vide.derive(function()
		local x = sizeHover().X.Offset

		return x * Params.SizeRatio
	end)

	local headerSize = Vide.derive(function()
		return textSize() * 1.5
	end)

	local function HoverUI()
		return HoverContainer(ZBatch(4, {
			ImageLabel({
				Image = ImageId.HoverBack.Id,
			}),
			TextContainer(Layout({
				TextLabel({
					Text = props.Header,
					Size = UDim2.fromScale(1, 0.05),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignement = Enum.TextYAlignment.Bottom,
					ZIndex = 9,
					TextSize = headerSize,
				}),
				TextLabel({
					Text = props.Description,
					Size = UDim2.fromScale(0.9, 0.6),
					ZIndex = 9,
					TextSize = textSize,
					TextYAlignement = Enum.TextYAlignment.Top,
				}),
			})),
		}))
	end

	return Vide.action(function(target: GuiObject)
		local shown = Vide.source(false)
		local isHover = Vide.source(false)

		local display: Vide.Source<boolean>

		if props.CanClick then
			Vide.effect(function()
				props.CanClick(shown())
			end)
		end

		if UserInputService.TouchEnabled then
			Vide.cleanup(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				local pos = input.Position
				local abs = target.AbsolutePosition
				local size = target.AbsoluteSize
				if pos.X >= abs.X and pos.X <= abs.X + size.X and pos.Y >= abs.Y and pos.Y <= abs.Y + size.Y then
					isHover(true)
				else
					isHover(false)
				end
			end))
		else
			Vide.cleanup(target.MouseEnter:Connect(function()
				isHover(true)
			end))

			Vide.cleanup(target.MouseLeave:Connect(function()
				isHover(false)
			end))
		end
		local id = {} -- table unique comme identifiant

		Vide.effect(function()
			if isHover() then
				activeHover(id)
			elseif activeHover() == id then
				activeHover(nil)
			end
		end)

		display = Vide.derive(function()
			local canShow = props.Show()
			local hover = isHover()
			local isActive = activeHover() == id

			if not canShow then
				return
			end
			if shown() then
				return isActive
			end -- ferme si un autre devient actif
			if hover and not isActive then
				return false
			end -- locked par un autre
			return hover
		end)

		Vide.mount(function()
			return Vide.show(display, function()
				shown(true)
				Vide.cleanup(RunService.RenderStepped:Connect(function()
					local pos = target.AbsolutePosition
					local size = target.AbsoluteSize

					pos += size * Vector2.new(1, 0.5)

					size *= props.SizeScale or Vector2.one

					positionHover(UDim2.fromOffset(pos.X, pos.Y))
					sizeHover(UDim2.fromOffset(size.X, size.Y))
				end))

				Vide.cleanup(function()
					shown(false)
				end)
				return HoverUI()
			end)
		end, screenHover)
	end)
end
