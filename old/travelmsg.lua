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
			mapId = mapId,
		}
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

-- 购买建筑物
Net.CmdOpenNewBuildCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.OpenNewBuildCmd_S"
	if cmd.data == nil or cmd.data.buildId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local mapId = cmd.data.buildId
	local uid = laccount.Id

	local ret, desc, level = TravelMgr.OpenNewBuild(uid, buildId)
		res["data"] = {
			resultCode = ret,
			desc = desc,
			buildId = buildId,
		}
	return res
end

-- 升级建筑物
Net.CmdUpLevelBuildCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UpLevelBuildCmd_S"
	if cmd.data == nil or cmd.data.buildId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local mapId = cmd.data.buildId
	local level = cmd.data.buildId or 0
	local uid = laccount.Id

	local ret, desc, newLevel = TravelMgr.UpLevelBuild(uid, buildId, level)
		res["data"] = {
			resultCode = ret,
			desc = desc,
			buildId = buildId,
			level = newLevel,
		}
	return res
end
