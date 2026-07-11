local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

return function(props: Type.Props & {
	Image: string,
	OnClick: () -> ()?,
	OnBegan: () -> ()?,
	OnLeave: () -> ()?,
	ImageColor3: Color3?,
	ImageTransparency: number?,
	ByPass: boolean?,
	ButtonEnabled: Vide.Source<boolean>?,
})
	local defaultProps = {
		BackgroundTransparency = 1,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ImageColor3 = Color3.fromHex("#ffffff"),
		ImageTransparency = 0,
		Visible = true,
	}

	local button: ImageButton = Vide.create("ImageButton")(FastProps({
		Props = props,
		Default = defaultProps,
		HardProps = {
			Image = props.Image,
		},
	}))

	local function isActivated(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.Gamepad1
	end

	local pressing = Vide.source(false)

	if props.OnClick then
		Vide.cleanup(button.InputBegan:Connect(function(input: InputObject)
			if not isActivated(input) then
				return
			end
			pressing(true)
		end))

		--[[Vide.cleanup(button.MouseLeave:Connect(function()
			pressing(false)
		end))]]

		Vide.cleanup(button.MouseLeave:Connect(function()
			if UserInputService.TouchEnabled then
				return
			end

			pressing(false)
		end))

		Vide.cleanup(button.InputEnded:Connect(function(input: InputObject)
			if not isActivated(input) then
				return
			end

			if not pressing() then
				return
			end

			if props.ByPass then
				props.OnClick()
				return
			end
			local pos = input.Position
			local absPos = button.AbsolutePosition
			local absSize = button.AbsoluteSize

			if
				pos.X >= absPos.X
				and pos.X <= absPos.X + absSize.X
				and pos.Y >= absPos.Y
				and pos.Y <= absPos.Y + absSize.Y
			then
				if props.ButtonEnabled and not props.ButtonEnabled() then
					pressing(false)
					return
				end

				props.OnClick()
			end
			pressing(false)
		end))
	end

	if props.OnBegan then
		Vide.cleanup(button.InputBegan:Connect(function(input: InputObject)
			if not isActivated(input) then
				return
			end

			props.OnBegan()
		end))
	end

	if props.OnLeave then
		Vide.cleanup(button.MouseLeave:Connect(function()
			props.OnLeave()
		end))
	end

	return button
end
