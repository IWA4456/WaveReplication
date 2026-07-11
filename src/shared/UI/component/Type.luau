export type value<Props> = () -> Props | Props

export type Props = {
	Size: value<UDim2>?,
	Position: value<UDim2>?,
	BackgroundColor3: value<Color3>?,
	BackgroundTransparency: value<number>?,
	AnchorPoint: value<Vector2>?,
	SizeConstraint: value<Enum.SizeConstraint>?,
	AutomaticSize: value<Enum.AutomaticSize>?,
	ZIndex: value<number>?,
	Active: value<boolean>?,
	Visible: value<boolean>?,
	Rotation: value<boolean>?,
	Parent: Instance?,
	[number | string]: any,
}

export type DefaultProps = {
	Size: UDim2?,
	Position: UDim2?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	AnchorPoint: Vector2?,
	SizeConstraint: Enum.SizeConstraint?,
	AutomaticSize: Enum.AutomaticSize?,
	ZIndex: number?,
	Active: boolean?,
	Visible: boolean?,
	Rotation: boolean?,
	Parent: Instance?,
	[string]: any?,
}

return nil
