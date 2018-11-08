module("enum", package.seeall)

--[[
@file Enum type.
@brief In face, the enum type is a table in lua.
--]]

function create(tbl, idx)
	local enumTable = {}
	local enumIdx = idx or 0

	for i, v in ipairs(tbl) do
		enumTable[v] = enumIdx + i
	end

	return enumTable
end
