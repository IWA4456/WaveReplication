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

return deepEqualizer
