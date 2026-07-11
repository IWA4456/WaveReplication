return function(startIndex: number, elements: { GuiObject | (unknown) -> unknown })
	for _, element: GuiObject | any in elements do
		if typeof(element) ~= "Instance" then
			continue
		end

		local gui = element :: GuiObject

		gui.ZIndex = startIndex
		startIndex += 1
	end
	return elements
end
