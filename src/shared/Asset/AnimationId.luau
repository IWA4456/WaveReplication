local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animation = ReplicatedStorage.Animation

return {
	BasicAttack = {
		Id = animation.Basic_Slash1,
	},
	EnemyWalk = {
		Id = animation.Enemy_Walk,
		Loop = true,
		SpeedRatio = 0.2,
	},
	EnemyDeath = {
		Id = animation.Enemy_Death,
		Events = {
			"Fall",
			"Ground",
			"End",
		},
	},
	EnemyAttack = {
		Id = animation.Enemy_Punch,
		NumberOfHits = 2,
	},
	BasicAttack2 = {
		Id = animation.Basic_Slash2,
	},
}
