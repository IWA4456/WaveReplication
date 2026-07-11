export type EnemyGroup = {
	enemy: { [string]: {
		size: number,
	} },
	distance: number,
	spreadFactor: number,
	dimension: Vector2,
	time: number,
}

export type Wave = { EnemyGroup }

local wave: { [string]: Wave } = {
	["1"] = {
		{
			enemy = { ["Noob"] = { size = 10 } },
			distance = 40,
			spreadFactor = 3,
			dimension = Vector2.new(10, 10),
			time = 5,
		},
	},
}

return function(id)
	return wave[id]
end
