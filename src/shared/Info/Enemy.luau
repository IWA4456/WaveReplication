local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationId = require(ReplicatedStorage.Shared.Asset.AnimationId)
export type Enemy = {
	Health: number,
	Power: number,
	Speed: number,
	Name: string,
	Coins: number,
	Cost: number,
	Weight: number,
	MinBudget: number,
	MaxBudget: number,
}

local Enemy: { [string]: Enemy } = {
	["Noob"] = {
		Health = 15,
		Power = 2.5,
		Speed = 2,
		Name = "Noob",
		Coins = 10,
		Cost = 2,
		Weight = 50,
		MinBudget = 0,
		MaxBudget = 100,
	},
}

local hoverElement = {
	["Noob"] = "Head",
}

local animation = {
	["Noob"] = {
		Walk = AnimationId.EnemyWalk,
		Attack = AnimationId.EnemyAttack,
		Death = AnimationId.EnemyDeath,
	},
}

local metaModel = {}
metaModel.__index = metaModel

function metaModel:GetHover(clonedModel: Model): Instance
	local hoverPart = clonedModel:FindFirstChild(hoverElement[self.Id])
	assert(hoverPart, "Hover part not found")

	return hoverPart
end

function metaModel:GetAnimation(): Animation
	return animation[self.Id]
end

local function New(id: string): EnemyInfo
	assert(Enemy[id], `The id {id} was not found the info list`)
	local clone = table.clone(Enemy[id])
	clone.Id = id
	setmetatable(clone, metaModel)
	return clone :: EnemyInfo
end

local function GetlistWithBudget(budget: number): { string }
	local list = {}
	for id, info in Enemy do
		if info.MaxBudget < budget or budget < info.MinBudget then
			continue
		end
		table.insert(list, id)
	end
	return list
end

local function PickEnemy(selectedEnemies: { string }, leftBudget: number): string?
	local totalWeight = 0
	local weighted = {}

	for _, id in selectedEnemies do
		local info = New(id)

		if info.Cost > leftBudget then
			continue
		end

		totalWeight += info.Weight

		table.insert(weighted, {
			Id = id,
			Weight = info.Weight,
		})
	end

	if totalWeight == 0 then
		return
	end

	local rng = math.random(1, totalWeight)

	local cumulative = 0

	for _, enemy in weighted do
		cumulative += enemy.Weight

		if rng <= cumulative then
			return enemy.Id
		end
	end
	return
end

export type EnemyInfo = Enemy & typeof(metaModel) & { Id: string }

return {
	New = New,
	GetSelected = GetlistWithBudget,
	Pick = PickEnemy,
}
