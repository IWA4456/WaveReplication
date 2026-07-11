export type HexSide = "Top" | "TopLeft" | "TopRight" | "Bottom" | "BottomLeft" | "BottomRight"

export type HexImage = {
	Id: string,
	Ratio: number?,
	Position: UDim2?,
	Size: UDim2?,
}

export type HexCell = {
	HexId: HexId,
	NextCells: { [HexSide]: HexId },
	Cost: number,
	Color: string,
	ImageId: { HexImage } | HexImage,
	Label: string,
	Description: string,
}

export type HexCellPlus = HexCell & {
	PreviousCell: HexId,
}

export type HexId = string | "Center"

export type HexIdList = { [HexId]: HexCell }

export type HexInfo = { [HexId]: HexCellPlus }

export type HexData = { HexId } --serverSide

export type HexEffect = { [HexId]: () -> () }

return nil
