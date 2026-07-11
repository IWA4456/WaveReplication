local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local ExitButton = require(script.Parent.ExitButton)
local InventoryCard = require(script.Parent.InventoryCard)
local InventoryTitle = require(script.Parent.InventoryTitle)
local ImageId = require(ReplicatedStorage.Shared.Asset.ImageId)
local DeepEqualizer = require(ReplicatedStorage.Shared.DeepEqualizer)
local Weapon = require(ReplicatedStorage.Shared.Info.Weapon)
local ImageLabel = require(ReplicatedStorage.Shared.UI.Primitive.ImageLabel)
local ScrollingFrame = require(ReplicatedStorage.Shared.UI.Primitive.ScrollingFrame)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local Type = require(ReplicatedStorage.Shared.UI.component.Type)

type CardInfo = {
	Id: string,
	Extra: { [string]: any }?,
	Count: number,
	Index: number,
}

type InventoryInfo = { CardInfo }

return function(props: Type.Props & {
	ShowSelf: Vide.Source<boolean>,
	Inventory: Vide.Source<InventoryInfo>,
	EquipEvent: (Weapon.EquipData) -> (),
	EquippedId: Vide.Source<Weapon.EquipData>,
})
	local InventoryContainer = Container(props)

	local ratio = UISizeRatio({
		Ratio = ImageId.InventoryBackground.Ratio,
	})

	return InventoryContainer({
		ratio(ImageLabel({
			Image = ImageId.InventoryBackground.Id,
			ExitButton({
				OnClick = function()
					props.ShowSelf(false)
				end,
				Size = UDim2.fromScale(0.27, 0.24),
				Position = UDim2.fromScale(0.8425, -0.06),
			}),
			InventoryTitle({
				Size = UDim2.fromScale(0.675, 0.887),
				Position = UDim2.fromScale(0.197, 0.087),
			}),
			ScrollingFrame({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.9),
				Size = UDim2.fromScale(0.85, 0.74),
				Vide.indexes(props.Inventory, function(value: () -> CardInfo, index: number)
					local weaponInfo = Vide.derive(function()
						local data = Weapon.Data(value().Id, value().Extra)

						return Weapon.NewFromData(data)
					end)

					local Count = Vide.derive(function()
						return value().Count
					end)

					local EquipData = Vide.derive(function()
						return {
							Id = value().Id,
							Index = value().Index,
						}
					end)

					local isEquipped = Vide.derive(function()
						return DeepEqualizer(EquipData(), props.EquippedId())
					end)

					return InventoryCard({
						OnClick = function()
							if not props.EquipEvent then
								return
							end

							props.EquipEvent(EquipData())
						end,
						WeaponInfo = weaponInfo,
						Size = UDim2.fromScale(0.19, 0.4),
						IsEquipped = isEquipped,
						Count = Count,
					})
				end),
			}),
		})),
	})
end
