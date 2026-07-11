local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local UICorner = require(ReplicatedStorage.Shared.UI.component.Modifier.UICorner)

local Type = require(ReplicatedStorage.Shared.UI.component.Type)
type Props = Type.Props

local Mask = require(ReplicatedStorage.Shared.UI.component.Base.Mask)({
	Size = UDim2.fromScale(0.96, 0.87),
	Modifier = { UICorner({
		CornerRadius = UDim.new(3, 0),
	}) },
	Position = UDim2.fromScale(0.5, 0.478),
})

local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UIStroke = require(ReplicatedStorage.Shared.UI.component.Modifier.UIStroke)
local FastProps = require(ReplicatedStorage.Shared.UI.component.Utils.FastProps)

local SHAKE_INTENSITY = 6
local SHAKE_SIDE = { -1, 1 }

return function(props: Type.Props & {
	Source: Vide.Source<number>,
	Max: number,
	TopColor: Color3,
	BottomColor: Color3,
	Shake: boolean,
	Display: Vide.Source<string>,
} & Type.Props)
	local smooth = Vide.spring(props.Source, 0.8, 0.8)

	local shake: () -> Vector2, control = Vide.spring(Vide.source(Vector2.zero), 0.25, 0.3)

	Vide.effect(function()
		if props.Source() == props.Max then
			return
		end
		local x = SHAKE_SIDE[math.random(1, 2)] * SHAKE_INTENSITY
		local y = SHAKE_SIDE[math.random(1, 2)] * SHAKE_INTENSITY

		control({
			impulse = Vector2.new(x, y),
		})
	end)

	local PosContainer = Vide.derive(function()
		if not props.Shake then
			return UDim2.fromScale(0.5, 0.5)
		end
		local offset = UDim2.fromScale(shake().X, shake().Y)
		return UDim2.fromScale(0.5, 0.5) + offset
	end)

	local LifeContainer = Container(FastProps({
		Props = props,
		Default = {
			Position = PosContainer,
		},
	}))

	local UI: GuiObject = LifeContainer({
		Vide.create("ImageLabel")({
			Image = ImageId.LifeBubble.Id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			BackgroundTransparency = 1,
		}),

		Mask(ZBatch(3, {
			Vide.create("Frame")({
				BackgroundColor3 = props.BottomColor,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(1, 1),
			}),

			Vide.create("Frame")({ -- greenBar
				BackgroundColor3 = props.TopColor,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = function()
					local ratio = smooth() / props.Max
					return UDim2.fromScale(ratio, 1)
				end,
			}),
		})),

		Vide.create("TextLabel")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 0.7),
			TextColor3 = Color3.fromHex("#FFFFFF"),
			TextScaled = true,
			ZIndex = 6,
			Font = Enum.Font.FredokaOne,
			BackgroundTransparency = 1,

			Text = props.Display,

			UIStroke({}),
		}),
	})
	if props.Parent then
		UI.Parent = props.Parent
	end
	return UI
end
