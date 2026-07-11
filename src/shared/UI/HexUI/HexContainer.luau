local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
return function()
	local HexContainer: Frame = Container({
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(1.3, 1.3),
	})({})

	return HexContainer,
		function()
			-- ╔════════════╗
			-- ║  Dragging  ║
			-- ╚════════════╝
			local dragging = Vide.source(false)
			local dragStart = Vide.source(Vector2.zero)
			local frameStart = Vide.source(HexContainer.Position)

			local frameGoal = Vide.source(HexContainer.Position)
			local sizeGoal = Vide.source(HexContainer.Size)

			local frameSmooth = Vide.spring(frameGoal, 0.3, 0.5)
			local sizeSmooth = Vide.spring(sizeGoal, 0.3, 1)

			Vide.effect(function()
				HexContainer.Position = frameSmooth()
				HexContainer.Size = sizeSmooth()
			end)

			local function isDragInput(input: InputObject): boolean
				return input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.Gamepad1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3
			end

			local function isDragMouvement(input: InputObject): boolean
				return input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
			end

			Vide.cleanup(UserInputService.InputBegan:Connect(function(input: InputObject, isOther: boolean)
				if not isDragInput(input) then
					return
				end
				dragging(true)
				local vec2 = Vector2.new(input.Position.X, input.Position.Y)
				dragStart(vec2)
				frameStart(HexContainer.Position)
			end))

			Vide.cleanup(UserInputService.InputChanged:Connect(function(input: InputObject)
				if not isDragMouvement(input) or not dragging() then
					return
				end
				local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart()
				frameGoal(frameStart() + UDim2.fromOffset(delta.X, delta.Y))
			end))

			Vide.cleanup(UserInputService.InputEnded:Connect(function(input: InputObject)
				if not isDragInput(input) then
					return
				end
				dragging(false)
			end))

			-- ╔════════╗
			-- ║  Zoom  ║
			-- ╚════════╝

			local function isZoomInput(input: InputObject): boolean
				return input.UserInputType == Enum.UserInputType.MouseWheel
			end

			Vide.cleanup(UserInputService.InputChanged:Connect(function(input: InputObject)
				if not isZoomInput(input) then
					return
				end

				local delta = input.Position.Z
				local currentSize = HexContainer.Size
				local scale = 1 + (delta * 0.4)

				local targetSize = Vector2.new(currentSize.X.Scale * scale, currentSize.Y.Scale * scale)

				sizeGoal(UDim2.fromScale(math.clamp(targetSize.X, 0.5, 2), math.clamp(targetSize.Y, 0.5, 2)))
			end))

			Vide.cleanup(function()
				HexContainer.Position = UDim2.fromScale(0.5, 0.5)
				HexContainer.Size = UDim2.fromScale(1.3, 1.3)
			end)

			return HexContainer
		end
end
