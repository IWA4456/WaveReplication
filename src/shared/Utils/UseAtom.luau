local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Vide = require(ReplicatedStorage.Packages.Vide)

return function<T>(Atom: Charm.Atom<T>): Vide.Source<T>
	return Charm.untracked(function()
		local source = Vide.source(Atom())

		Vide.cleanup(Charm.effect(function()
			source(Atom())
		end))

		return source
	end)
end
