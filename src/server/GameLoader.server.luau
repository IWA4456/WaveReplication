local Modules = script.Parent:GetDescendants()

for _, module: ModuleScript in Modules do
	if not module:IsA("ModuleScript") then
		continue
	end
	task.spawn(function()
		require(module)
	end)
end
