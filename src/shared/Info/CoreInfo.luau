type Info = {
	Health: number,
	Radius: number,
	Id: string,
}

local CoreInfo: { [string]: Info } = {
	["1"] = {
		Health = 100,
		Radius = 5,
		Id = "1",
	},
}

local metaCoreInfo = {}
metaCoreInfo.__index = metaCoreInfo

function metaCoreInfo:GetModel()
	--TODO
end

export type CoreInfo = Info & typeof(metaCoreInfo)

return function(id: string): CoreInfo?
	if not CoreInfo[id] then
		return
	end
	assert(CoreInfo[id], "There is no coreInfo related to : " .. id)
	local coreInfo = table.clone(CoreInfo[id])

	return setmetatable(coreInfo, metaCoreInfo)
end
