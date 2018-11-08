module('TravelMgr', package.seeall)
-- 旅行相关 公共代码 

-- 地图状态枚举
ENUM_MAP_STATUS = {
	CLOSE = 0, -- 关闭
	OPEN = 1, -- 可开启
	CANOPEN = 2, -- 已开启
}
--建筑状态枚举
ENUM_BUILD_STATUS = {
	CLOSE = 0, -- 关闭
	OPEN = 1, -- 可开启
	CANOPEN = 2, -- 已开启
}

-- 创建地图数据表
function CreatDb(gameId)
	MAP_DB_NAME = tostring(gameId) .. "mapinfo"		-- 数据表名字常量 由指定游戏调用时 再传入其gameid
	unilight.createdb(MAP_DB_NAME, "uid")
end

-- 地图创建
function UserMapConstuct(uid)
	local userMaps = {
		uid 			= uid,			-- 玩家id
		mapLists 		= {},			-- 地图数组
	}
	for i,v in ipairs(TableMap) do 
		local buildList = {}
		for m,n in ipairs(TableBuild) do
			if n.mapId == i then
				local buildInfo = {
					buildId = m,
					status = ENUM_BUILD_STATUS.CLOSE,
					level = 0,
					leftCD = 0,
				}
				table.insert(buildList, buildInfo)
			end
		end
		local userMap = {
			mapId 	= i,                     -- id
			status 	= ENUM_MAP_STATUS.CLOSE, -- 状态
			buildList = buildList,           --建筑组       				  		          
			}
		table.insert(userMaps.mapLists, userMap)
	end

	MapUpdate(userMaps)

	return userMaps
end

-- 更新
function MapUpdate(userMaps)
	-- 更新节点时间
	userMaps.time = os.time()
	-- 存档
	unilight.savedata(MAP_DB_NAME, userMaps)
end


--离线时建筑CD存起来
function OffLineRecord(uid)
	local userMaps = GetMapInfo(uid)
	for k,v in ipairs(userMaps.mapLists) do
		for m,n in ipairs(userMaps.mapLists[k].buildList) do
			if n.status == ENUM_BUILD_STATUS.OPEN then
				userMaps.mapLists[k].buildList[m].leftCD = userMaps.mapLists[k].buildList[m].leftCD - os.time()
			end
		end
	end
	MapUpdate(userMaps)
end

-- 上线获取地图列表
function SendMapList(uid)
	local mapData = GetMapInfo(uid)
	local res = {}
	res["do"] = "Cmd.GetMapListCmd_S"
	res["data"] = mapData.mapLists
	unilight.success(laccount, res)
end

-- 获取地图信息
function GetMapInfo(uid)
	-- 从数据库中 获取该玩家数据
	local mapData = unilight.getdata(MAP_DB_NAME, uid)

	-- 如果为空 或者 数据不为当天数据 则新建
	if mapData == nil  then
		return UserMapConstuct(uid)
	end	

	return mapData
end

-- 打开地图
function OpenTravelMap(uid, mapId)
	local tableMap = TableMap[MapId]
	local userMaps = GetMapInfo(uid)
	local index = 0
	for i,v in ipairs(userMaps.mapLists) do
		if v.MapId == mapId then
			index = i
			break
		end
	end
	if index == 0 then 
		unilight.info("玩家 当前不存在该地图：" .. mapId)
		return 2, "玩家 当前不存地图任务"
	end
	if userMaps.mapLists[index].status	== ENUM_MAP_STATUS.CLOSE then
		unilight.info("该地图暂时不可开启: " .. mapId)
		return 3, "该地图暂时不可开启"
	elseif userMaps.mapLists[index].status	== ENUM_MAP_STATUS.OPEN then 
		unilight.info("该地图已开启: " .. mapId)
		return 4, "该地图已开启"
	else
		--扣钱
		local needMoney = TableMap[MapId].needMoney
		userInfo:deductMoney(needMoney)
		userMaps.mapLists[index].status	= ENUM_MAP_STATUS.OPEN
		MapUpdate(userMaps)
		return 0, "地图开启成功"
	end	
end

--快速跳转
function FastSkipMap(uid, mapId)
	local userMaps = GetMapInfo(uid)
	if userMaps.mapLists[mapId] and userMaps.mapLists[mapId].status	~= ENUM_MAP_STATUS.OPEN then
		return 1, "地图处于未开启状态"
	elseif userMaps.mapLists[mapId] then
		return 0, "允许跳转"
	end
end

--根据玩家金币更新地图状态
function UpdateMapStatus(uid)
	local userMaps = GetMapInfo(uid)
	for k,v in ipairs(userMaps.mapLists) do
		local updata_tag = true
		for m,n in ipairs(userMaps.mapLists[k].buildList) do
			if n.status == ENUM_BUILD_STATUS.CLOSE then
				updata_tag = false
				break
			end
		end
		if updata_tag and v.status == ENUM_MAP_STATUS.CLOSE and userInfo.chips >= TableMap[k].needMoney then
			userMaps.mapLists[k].status = ENUM_MAP_STATUS.CANOPEN
		end
	end
	MapUpdate(userMaps)
end

--根据建筑开启情况更新下一个地图状态
function UpdataNextMapStatus(uid, mapId)
	local userMaps = GetMapInfo(uid)
	if userMaps.mapLists[mapId].status == ENUM_MAP_STATUS.CLOSE then
		local updata_tag = true
		--for k,v in ipairs(userMaps.mapLists[mapId].buildList) do
		--	if v.status == ENUM_BUILD_STATUS.CLOSE then
		--		updata_tag = false
		--		break
		--	end
		--end
		if updata_tag and userMaps.mapLists[mapId + 1] and userInfo.chips >= TableMap[mapId + 1].needMoney then
			userMaps.mapLists[mapId + 1].status = ENUM_MAP_STATUS.CANOPEN
		end
		MapUpdate(userMaps)
	end
end

--开启新建筑
function OpenNewBuild(uid, buildId)
	local userMaps = GetMapInfo(uid)
	local mapId = TableBulid[buildId].mapId
	if not userMaps.mapLists[mapId] then
		return 1, "该地图不存在"
	end
	if userMaps.mapLists[mapId].status ~= ENUM_MAP_STATUS.OPEN then
		return 2, "该地图未开启"
	else
		local buildList = userMaps.mapLists[mapId].buildList
		if not buildList or not buildList[buildId] then
			return 3, "该建筑不存在"
		end
		if buildList and buildList[buildId] and buildList[buildId].status ~= ENUM_BUILD_STATUS.CANOPEN then
			return 4, "该建筑暂时不可购买"
		else
			local needMoney = TableBulid[buildId].needMoney
			if UserInfo.chips >= needMoney then
				userInfo:deductMoney(needMoney)
				userMaps.mapLists[mapId].buildList[buildId].status = ENUM_BUILD_STATUS.OPEN
				userMaps.mapLists[mapId].buildList[buildId].leftCD = TableBulid[buildId].CD + os.time()
				MapUpdate(userMaps)
				UpdataNextMapStatus(uid, mapId)
				return 0, "建筑开启成功"
			else
				return 5, "金钱不足"
			end
		end
	end
end

--升级建筑
function UpLevelBuild(uid, buildId, level)
	local userMaps = GetMapInfo(uid)
	local mapId = TableBulid[buildId].mapId
	if not userMaps.mapLists[mapId] then
		return 1, "该地图不存在"
	end
	if userMaps.mapLists[mapId].status ~= ENUM_MAP_STATUS.OPEN then
		return 2, "该地图未开启"
	else
		local buildList = userMaps.mapLists[mapId].buildList
		if not buildList or not buildList[buildId] then
			return 3, "该建筑不存在"
		end
		if buildList and buildList[buildId] and buildList[buildId].status ~= ENUM_BUILD_STATUS.OPEN then
			return 4, "该建筑还未开启"
		else
			local nowLevel = buildList[buildId].level
			if level > 0 then
				for i = 1, level - nowLevel do
					local needMoney = TableBulid[nowLevel].needMoney
					if UserInfo.chips >= needMoney then
					 	userInfo:deductMoney(needMoney)
					 	nowLevel = nowLevel + 1
					 	userMaps.mapLists[mapId].buildList[buildId].level = nowLevel
					else
						break	
					end
				end
				MapUpdate(userMaps)
				return 0, "升级成功", nowLevel
			else
				local needMoney = TableBulid[nowLevel+1].needMoney
				if UserInfo.chips >= needMoney then
					userInfo:deductMoney(needMoney)
					nowLevel = nowLevel + 1
					userMaps.mapLists[mapId].buildList[buildId].level = nowLevel
					return 0, "升级成功", nowLevel
				else
					return 5, "金钱不足"
				end
			end
		end
	end
end
