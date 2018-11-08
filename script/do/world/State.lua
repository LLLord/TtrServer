State =
{
	owner = nil,
	world = nil,
	id = 0,
	buildings = nil,
}

function State:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function State:init(owner, world, id)
	self.owner = owner
	self.world = world
	self.id = id
	self.buildings = {}

	table.insert(world.states, self.id, self)
end

function State:sn()
	local data = {
		id = self.id,
		buildings = {},
	}

	for i, building in pairs(self.buildings) do
		table.insert(data.buildings, building:sn())
	end
	
	return data
end

function State:loadFromDb(data)
	if data["buildings"] == nil then
		unilight.debug("No buildings")
		return false
	end

	for i, db_building in pairs(data.buildings) do
		local building = Building:new()
		building:init(self.owner, self, db_building.id, db_building.lv, db_building.buildLv)
	end

	return true
end

function State:buy(id) -- building ID
	if self.buildings[id] ~= nil then
		return ERROR_CODE.BUY_AGAIN
	end

	-- +1: level
	local cost = tonumber(TableLevelup.query(id, 1)["CostMoney"])
	
	if type(cost) ~= "number" then
		unilight.warn("Table[Levelup]'s CostMoney is error")
		return ERROR_CODE.TABLE_ERROR
	end
	
	if self.owner.money < cost then
		return ERROR_CODE.MONEY_NOT_ENOUGH
	end

	self.owner.money = self.owner.money - cost
	self.owner.star = self.owner.star + 1

	local friendInfo = FriendManager:GetFriendInfo(self.owner.uid)
	if friendInfo ~= nil then
		friendInfo.simpleData.star = self.owner.star
		friendInfo.simpleData.money = self.owner.money
	end

	RankListMgr:UpdateRankNode(RankListMgr.rank_type_star, self.owner.uid, self.owner.star)
	RankListMgr:UpdateRankNode(RankListMgr.rank_type_money, self.owner.uid, self.owner.money)

	local building = Building:new()
	building:init(self.owner, self, id, 1, 1)

	return ERROR_CODE.SUCCESS
end

function State:levelup(id) -- building ID
	if self.buildings[id] == nil then
		return ERROR_CODE.BUILDING_NOT_BUY
	end

	return self.buildings[id]:levelup()
end

function State:rebuild(id) -- building ID
	if self.buildings[id] == nil then
		return ERROR_CODE.BUILDING_NOT_BUY
	end

	return self.buildings[id]:rebuild()
end

function State:recalcStar()
	local star = 0

	for i, building in pairs(self.buildings) do
		star = star + building.lv
	end
	
	return star
end

function State:calcEarning()
	local money = 0

	for _,building in pairs(self.buildings) do
		money = money + building:earn()
	end

	return money
end
