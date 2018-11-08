Building = {
	owner = nil,
	state = nil,
	id = 0,
	lv = 1,
	buildLv = 1,
	lost = 0,
	produce = 0,
}

function Building:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Building:init(owner, state, id, lv, buildLv)
	self.owner = owner
	self.state = state
	self.id = id
	self.lv = lv
	self.buildLv = buildLv

	if self.buildLv >= 100 then
		self.buildLv = 99
	end

	self:recalc()

	table.insert(state.buildings, self.id, self)
end

function Building:recalc()
	--local words = "recalc building: {id: %d, lv: %d, buildLv: %d}"
	--unilight.debug(words.format(words, self.id, self.lv, self.buildLv))
--	self.produce = self:getValue("ProduceMoney") * self:getRebuildValue("Times")
	--local words = "recalc building: {id: %d, lv: %d, buildLv: %d, produce:%d}"
	--unilight.debug(words.format(words, self.id, self.lv, self.buildLv, self.produce))

	--建筑效率 = 	1 - 建筑效率提升% / (建筑效率提升% + 1)	
	local aaa = (1 - self.owner.UserProps:getUserProp("pBuildingProduceRate")/(self.owner.UserProps:getUserProp("pBuildingProduceRate") + 1)) * GlobalConst.Takt_Time
	--建筑产量 / 建筑效率 * 建筑改造加成 * (1 + 抓捕好友加成 * (1 + 好友亲密度加成) * (1 + 旅行团加成)) * 世界加成
	self.produce = self:getValue("ProduceMoney")* self:getRebuildValue("Times")/aaa *(self.owner.UserProps:getUserProp("pWorldGoldAddRatio") + 1)
	
	unilight.info("Building计算值:" .. self.produce .. ",建筑效率:" .. aaa .. ",建筑速率:" ..  self.owner.UserProps:getUserProp("pBuildingProduceRate") .. ",世界加成:" .. self.owner.UserProps:getUserProp("pWorldGoldAddRatio"))
end

-- Get value from Levelup table
function Building:getValue(key, isNext)
	if isNext == nil or isNext == false then
		if key == "CostMoney" or key == "ProductMoney" then
			return tonumber(TableLevelup.query(self.id, self.lv)[key])
		else
			return TableLevelup.query(self.id, self.lv)[key]
		end
	else
		if key == "CostMoney" or key == "ProductMoney" then
			return tonumber(TableLevelup.query(self.id, self.lv + 1)[key])
		else
			return TableLevelup.query(self.id, self.lv + 1)[key]
		end
	end
end

function Building:getRebuildValue(key, isNext)
	if isNext == nil or isNext == false then
		if key == "CostMoney" or key == "ProductMoney" then
			return tonumber(TableRebuild.query(self.id, self.buildLv)[key])
		else
			return TableRebuild.query(self.id, self.buildLv)[key]
		end
	else
		if key == "CostMoney" or key == "ProductMoney" then
			return tonumber(TableRebuild.query(self.id, self.buildLv + 1)[key])
		else
			return TableRebuild.query(self.id, self.buildLv + 1)[key]
		end
	end
end

function Building:sn()
	local data = {
		id = self.id,
		lv = self.lv,
		buildLv = self.buildLv,
	}
	return data
end

function Building:earn()
	return self.produce
end

function Building:levelup()
	local cost = self:getValue("CostMoney", true)

	if (cost == nil) then
		return ERROR_CODE.BUILDING_LEVEL_MAX
	end

	if type(cost) ~= "number" then
		unilight.warn("Table[Levelup]'s CostMoney is error")
		return ERROR_CODE.TABLE_ERROR
	end

	if UserInfo.CheckUserMoney(self.owner, static_const.Static_MoneyType_Gold, cost) == false then
		return ERROR_CODE.MONEY_NOT_ENOUGH
	end

	UserInfo.SubUserMoney(self.owner, static_const.Static_MoneyType_Gold, cost)

	self.lv = self.lv + 1
	self:recalc()
	self.owner.star = self.owner.star + 1

	--任务系统，任务完成情况
	self.owner.achieveTask:addProgress(TaskConditionEnum.BuildingLevelupEvent, 1)
	self.owner.dailyTask:addProgress(TaskConditionEnum.BuildingLevelupEvent, 1)
	

	local friendInfo = FriendManager:GetFriendInfo(self.owner.uid)
	if friendInfo ~= nil then
		friendInfo.simpleData.star = self.owner.star
	end

	RankListMgr:UpdateRankNode(RankListMgr.rank_type_star, self.owner.uid, self.owner.star)

	self.owner.mailMgr:addNew(2)

	return ERROR_CODE.SUCCESS
end

function Building:rebuild()
	local row = TableRebuild.query(self.id, self.buildLv + 1)

	if row == nil then
		return ERROR_CODE.BUILDING_REBUILD_MAX
	end

	local needLv = row["NeedLv"]

	if type(needLv) ~= "number" then
		unilight.info("Table[Rebuild]'s needLv is error")
		return ERROR_CODE.TABLE_ERROR
	end

	if self.lv < needLv then
		return ERROR_CODE.BUILDING_LEVEL_NOT_ENOUGH
	end

	local cost = self:getRebuildValue("CostMoney", true)
	if type(cost) ~= "number" then
		unilight.info("Table[Rebuild]'s CostMoney is error")
		return ERROR_CODE.TABLE_ERROR
	end

	UserInfo.SubUserMoneyByUid(self.owner.uid, static_const.Static_MoneyType_Gold, cost)

	local diamond = row["CostDiamond"]

	if type(diamond) ~= "number" then
		unilight.info("Table[Rebuild]'s CostDiamond is error")
		return ERROR_CODE.TABLE_ERROR
	end

	UserInfo.SubUserMoneyByUid(self.owner.uid, static_const.Static_MoneyType_Diamond, diamond)

	self.buildLv = self.buildLv + 1
	self:recalc()

	--任务系统，任务完成情况
	self.owner.achieveTask:addProgress(TaskConditionEnum.BuildingChangeEvent, 1)
	self.owner.dailyTask:addProgress(TaskConditionEnum.BuildingChangeEvent, 1)

	self.owner.mailMgr:addNew(3)

	return ERROR_CODE.SUCCESS
end
