
local TableBuilding = TableBuilding
World =
{
	owner = nil,
	states = nil,
}

WORLD_CLICK_FACTOR = 0.04

function World:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function World:init(owner)
	self.owner = owner
	self.states = {}
end

function World:create()
	--At the beginning, there is only the first state with activated
	local state = State:new()
	state:init(self.owner, self, 101)
end

function World:createTemp()
	unilight.debug("Create a temp world")
	local state1 = State:new()
	state1:init(self.owner, self, 101)

	local building1 = Building:new()
	building1:init(self.owner, state1, 1, 2, 2)

	local building2 = Building:new()
	building2:init(self.owner, state1, 2, 2, 1)
	
	local state2 = State:new()
	state2:init(self.owner, self, 102)

	local building3 = Building:new()
	building3:init(self.owner, state2, 7, 1, 1)
end

function World:update()
	self.owner.money = self.owner.money + self:earn()
	
	unilight.debug("UID:" .. self.owner.uid .."Money:" .. self.owner.money)
end

--In normal case, it is unused
function World:recalcStar()
	local star = 0

	for i, state in pairs(self.states) do
		star = star + state:recalcStar()
	end

	unilight.debug("Recalc star:" .. star)
	return star
end

function World:sn()
	local data = {
		states = {},
	}

	local c = 0

	for i, state in pairs(self.states) do
		c = c + 1
	end

	local last = 101 + c - 1

	for i = 101, last do
		table.insert(data.states, self.states[i]:sn())
	end

	return data
end

function World:loadFromDb(data)
	if data["states"] == nil then
		unilight.warn("No states")
		return false
	end

	for i, db_state in pairs(data.states) do
		local state = State:new()
		state:init(self.owner, self, db_state.id)
		
		if state:loadFromDb(db_state) == false then
			return false
		end
	end

	return true
end

	
function World:levelup(stateId, buildingId)
	if self.states[stateId] == nil then
		return ERROR_CODE.BUILDING_STATE_NOT_OPEN
	end

	return self.states[stateId]:levelup(buildingId)
end

function World:buy(stateId, buildingId)
	if self.states[stateId] == nil then
		return ERROR_CODE.BUILDING_STATE_NOT_OPEN
	end

	return self.states[stateId]:buy(buildingId)
end

function World:openState(id) -- state ID
	local mapid = TableBuilding[id]["mapid"]	
	if self.states[mapid] ~= nil then
		return ERROR_CODE.OPEATE_AGAIN
	end

	--The first building of this state
	local costString = TableBuilding[id]["OpenCost"]
	unilight.info("openState计算值:" .. costString)
	--检测物品是否在item表  
        local args = string.split(costString, '_')
        if #args == 0 then
                return false,ERROR_CODE.TABLE_ERROR
        end
        local moneytype = tonumber(args[1])
        local moneynum = tonumber(args[2])	
	if UserInfo.CheckUserMoneyByUid(self.owner.uid,moneytype,moneynum) == false then
		return ERROR_CODE.MONEY_NOT_ENOUGH
	end
	--local cost = tonumber(string.match(string.match(costString, ",%d+"), "%d+"))

	local state = State:new()
	state:init(self.owner, self, mapid)
	UserInfo.SubUserMoneyByUid(self.owner.uid,moneytype,moneynum)

	local items = {}
	table.insert(items, {1002, 1})
	table.insert(items, {1, 100})
	self.owner.mailMgr:addNew(1, "Hello Mail", "就是我", items)

	return ERROR_CODE.SUCCESS
end

function World:rebuild(stateId, buildingId)
	if self.states[stateId] == nil then
		return ERROR_CODE.BUILDING_STATE_NOT_OPEN
	end

	return self.states[stateId]:rebuild(buildingId)
end

function World:earn()
	local money = 0

	for k,state in pairs(self.states) do
		money = money + state:calcEarning()
	end
	money = money + self.owner.UserProps:getUserProp("pWorldGoldAdd") * (1 + self.owner.UserProps:getUserProp("pWorldGoldAddRatio")) 
	return money
end

function World:click(stateId, times, critical)
	if critical > times then
		critical = times
	end
	if self.states[stateId] == nil then
		return ERROR_CODE.BUILDING_STATE_NOT_OPEN
	end

	local earning = self.states[stateId]:calcEarning()
	earning = earning * GlobalConst.Click_Factor
	earning = earning + self.owner.UserProps:getUserProp("pClickGoldAdd") * (self.owner.UserProps:getUserProp("pWorldGoldAddRatio") + 1) 
	earning = earning * (1 + self.owner.UserProps:getUserProp("pClickGoldAddRatio"))
	if type(critical) == "number" and critical ~= 0 then
		earning = earning * critical * GlobalConst.Click_Crit_Multiple
		earning =  earning + earning * (times - critical)
	end
	unilight.info("click计算值:" .. math.ceil(earning))

	UserInfo.AddUserMoneyByUid(self.owner.uid, static_const.Static_MoneyType_Gold, math.ceil(earning))

	--任务系统，任务完成情况
	self.owner.achieveTask:addProgress(TaskConditionEnum.ClickEvent, times)
	self.owner.dailyTask:addProgress(TaskConditionEnum.ClickEvent, times)

	local friendInfo = FriendManager:GetFriendInfo(self.owner.uid)
	if friendInfo ~= nil then
		friendInfo.simpleData.click = friendInfo.simpleData.click + times
		RankListMgr:UpdateRankNode(RankListMgr.rank_type_click, self.owner.uid, friendInfo.simpleData.click)
	end

	return 0
end
