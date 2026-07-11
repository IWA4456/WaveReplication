local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
return function()
	return Vide.action(function(target: Instance)
		Vide.cleanup(target)
	end)
end
