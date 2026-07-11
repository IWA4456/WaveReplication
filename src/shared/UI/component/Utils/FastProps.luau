local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Type = require(ReplicatedStorage.Shared.UI.component.Type)

--- Builds the final props table for a Vide component.
---
--- - `Props` — props passed by the caller
---   - Numeric indexes (actions, children) are always included
---   - String keys are only included if they exist in `Default`
--- - `Default` — fallback values for string keys not provided by the caller
--- - `DefaultModifier` — default UIComponents added as children; replaced if caller passes same class
--- - `HardProps` — props that always override
--- - `Children` — GuiObjects always appended as children
---
--- @param settings { Props, Default, DefaultModifier?, HardProps?, Children? }
--- @return table
--- ```lua
--- return Vide.create("TextLabel")(FastProps({
---     Props = props,
---     Default = defaultProps,
---     DefaultModifier = { UIStroke({}) },
--- }))
--- ```
return function(settings: {
	Props: Type.Props,
	Default: Type.Props,
	DefaultModifier: { UIComponent }?,
	HardProps: Type.Props?,
	Children: { GuiObject }?,
})
	local props = {}

	for key, value in settings.Props do
		if type(key) == "number" then
			if settings.DefaultModifier and typeof(value) == "Instance" then
				local inst = value :: Instance
				local found = nil

				for index, component in settings.DefaultModifier do
					if component.ClassName ~= inst.ClassName then
						continue
					end
					found = index
				end

				if found then
					table.remove(settings.DefaultModifier, found)
				end
			end

			table.insert(props, value)
			continue
		end

		if settings.Default[key] == nil then
			continue
		end
		props[key] = value
	end

	for key, value in settings.Default do
		if props[key] ~= nil then
			continue
		end

		props[key] = value
	end

	if settings.DefaultModifier then
		for _, component in settings.DefaultModifier do
			table.insert(props, component)
		end
	end

	if settings.HardProps then
		for key, value in settings.HardProps do
			props[key] = value
		end
	end

	if settings.Children then
		for _, guiobj in settings.Children do
			table.insert(props, guiobj)
		end
	end

	return props
end
