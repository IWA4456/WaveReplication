local function deepEqualizer(prev: {}, next: {}): boolean
	if prev == nil or next == nil then
		if prev == next then
			return true
		else
			return false
		end
	end
	for key, value in next do
		if type(value) == "table" then
			if not deepEqualizer(prev[key], value) then
				return false
			end
		elseif prev[key] ~= value then
			return false
		end
	end

	return true
end

function popRandom<T>(tab: { T }): T
	local index = math.random(1, #tab)
	local value = tab[index]
	tab[index] = tab[#tab]
	tab[#tab] = nil
	return value
end

function isEmpty(tab: { [any]: any })
	for _, _ in tab do
		return false
	end
	return true
end

return {
	deepEqualizer = deepEqualizer,
	popRandom = popRandom,
	isEmpty = isEmpty,
}
