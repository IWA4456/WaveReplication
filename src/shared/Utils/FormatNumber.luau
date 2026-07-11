local format = {
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

local params = {
	DECIMAL = 2,
	MINIMUM = 1e3,
}

return function(number: number): string
	if number < params.MINIMUM then
		return tostring(number)
	end

	for _, entry in ipairs(format) do
		local value = entry[1]
		local suffix = entry[2]

		if number >= value then
			local shortened = number / value
			local formatted = string.format("%." .. params.DECIMAL .. "f", shortened)

			-- Supprime les zéros inutiles
			formatted = formatted:gsub("%.?0+$", "")

			return formatted .. suffix
		end
	end

	return tostring(number)
end
