local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local ImageButton = require(ReplicatedStorage.Shared.UI.Primitive.ImageButton)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local TextLabel = require(ReplicatedStorage.Shared.UI.Primitive.TextLabel)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local ZBatch = require(ReplicatedStorage.Shared.UI.component.Base.ZBatch)
local HoverEffect = require(ReplicatedStorage.Shared.UI.component.Behavior.HoverEffect)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

local image = {
	Green = "rbxassetid://118131313887463",
}
local ratio = 221 / 239

return function(props: Type.Props & {
	WeaponInfo: Vide.Source<Weapon.WeaponMeta>,
	IsEquipped: Vide.Source<boolean>,
	OnClick: () -> (),
	Count: Vide.Source<number>,
})
	local PropsContainer = Container(props)

	local RatioContainer = Container({})

	local HoverContainer = Container({})

	local ratioSize = UISizeRatio({
		Ratio = ratio,
	})

	local imageContent = Vide.derive(function()
		return props.WeaponInfo():GetImage()
	end)

	local ratioWeapon = UISizeRatio({
		Ratio = Vide.derive(function()
			return imageContent().Ratio
		end),
	})

	local Label = Vide.derive(function()
		return props.WeaponInfo().Name
	end)

	local function EquipStamp()
		local ratioLabel = UISizeRatio({
			Ratio = ImageId.Equipped.Ratio,
		})

		local sizeGoal, sizeControls = Vide.spring(Vide.source(UDim2.fromScale(1, 0.4)), 0.4, 0.6)

		local rotation, rotControls = Vide.spring(Vide.source(0), 1.2, 0.5)

		local StampContainer = Container({
			Size = sizeGoal,
			Position = UDim2.fromScale(0.5, 0.4),
			ZIndex = 99,
		})

		rotControls({
			position = 20,
		})
		sizeControls({
			position = UDim2.fromScale(2, 1.6),
		})

		return StampContainer({
			ratioLabel(ImageLabel({
				Image = ImageId.Equipped.Id,
				ZIndex = 99,
				Rotation = rotation,
			})),
		})
	end

	local CounterText = Vide.derive(function()
		return `x{props.Count()}`
	end)

	return PropsContainer({
		HoverContainer({
			ratioSize(RatioContainer(ZBatch(3, {
				ImageButton({
					Image = image.Green,
					OnClick = props.OnClick,
				}),
				ratioWeapon(ImageLabel({
					Image = function()
						return imageContent().Id
					end,
					Size = UDim2.fromScale(0.55, 0.5),
				})),
				HoverEffect({
					TargetParent = true,
				}),
				TextLabel({
					Text = Label,
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 0.95),
					Size = UDim2.fromScale(1, 0.25),
				}),
				TextLabel({
					Text = CounterText,
					AnchorPoint = Vector2.new(0, 0),
					Position = UDim2.fromScale(0.1, 0),
					Size = UDim2.fromScale(0.3, 0.23),
				}),
				Vide.show(props.IsEquipped, EquipStamp),
			}))),
		}),
	})
end
