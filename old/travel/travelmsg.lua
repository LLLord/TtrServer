
-- 获取地图列表
Net.CmdGetMapListCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetMapListCmd_S"

	local uid = laccount.Id
	local mapList = TravelMgr.GetMapList(uid)

	res["data"] = {
		resultCode = 0,
		desc = "获取地图列表成功",
		mapList = mapList,
	}
	return res
end

-- 开启地图
Net.CmdOpenTravelMapCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.OpenTravelMapCmd_S"
	if cmd.data == nil or cmd.data.mapId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local mapId = cmd.data.mapId
	local uid = laccount.Id

	local ret, desc, mapList = TravelMgr.OpenTravelMap(uid, mapId)
		res["data"] = {
			resultCode = ret,
			desc = desc,
			mapList = mapList,
		}
	end
	return res
end

-- 快速跳转
Net.CmdFastSkipMapCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.FastSkipMapCmd_S"

	local uid = laccount.Id
	if cmd.data == nil or cmd.data.mapId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end

	local ret, desc = TravelMgr.FastSkipMap(uid, cmd.data.mapId)
	res["data"] = {
		resultCode = ret,
		desc = desc,
	}
	return res
end