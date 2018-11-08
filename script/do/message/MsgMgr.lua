MsgTypeEnum = 
{
	FriendApply = 1,							--好友请求
	FriendRobbed = 2,							--好友被抢
	TripGroupFriendFinishEmploy = 3,			--你的旅行团的好友完成雇佣
	FriendRobbedWithFailure = 4,				--好友被抢，但失败了
	TripGroupMeFinishEmploy = 5,				--好友的旅行团的你完成雇佣
}


MSG_MAX = 50
MSG_KEEP_TIME = 86400 -- 24 * 3600

--[[ format
MsgUserInfo
{
	uid = 0,
	male = true,
	nickName = "",
	star = 0,
}


MsgRecord =
{ 
	id = 0,
	time = nil,
	msgType = 0,
	contents = nil,
	who = nil,
}
--]]

MsgMgr = 
{
	owner = nil,
	records = nil,
	id = 0,
}

function MsgMgr:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function MsgMgr:init(owner)
	self.owner = owner
	self.records = {}
end

tempMsgs = 
{
	--uid		Male		nickName	star		msgType						arguments
	{{1000,		true,		"猪x肠",	100},		MsgTypeEnum.FriendApply,	{}},
	{{1001,		false,		"黄大明",	100000},	MsgTypeEnum.FriendRobbed,	{}},
	{{1002,		true,		"张国清",	911},		MsgTypeEnum.TripGroupFriendFinishEmploy, {"100"}},
	{{1002,		false,		"Hello Kitty",	22},	MsgTypeEnum.FriendRobbedWithFailure, {}},
	{{1002,		true,		"李有才",	25},		MsgTypeEnum.TripGroupMeFinishEmploy, {"50"}},
}

function MsgMgr:createTemp()
	unilight.debug("Create temp msgs")

	for i, msg in pairs(tempMsgs) do
		local whoData = msg[1]

		local who = {
			uid = whoData[1],
			male = whoData[2],
			nickName = whoData[3],
			star = whoData[4],
		}
	
		self:add(who, msg[2], msg[3])
	end
end

function MsgMgr:sn()
	local data = {
		id = self.id,
		records = self.records,
	}

	return data
end

function MsgMgr:loadFromDb(data)
	self.id = data.id
	self.records = data.records
end

--Push msg to client
function MsgMgr:addNew(who, msgType, args)
	local msg = self:add(who, msgType, args)
	
	--push client
	local res = {}
	res["do"] = "Cmd.MsgNewCmd_S"
	res["data"] = {
		record = msg
	}

	unilight.response(self.owner.laccount, res)
	--self.owner.laccount.SendString(res)
end

--contents: string array
function MsgMgr:add(who, msgType, args)
	self.id = self.id + 1
	local msg = message.create(self.id, who, msgType, args)
	table.insert(self.records, msg)

	while (#self.records >= MSG_MAX) do
		unilight.debug("Msgs is more than " .. MSG_MAX .. ", remove the first")
		table.remove(self.records, 1)
	end

	return msg
end

function MsgMgr:clean()
	local indexes = {}
	local time = os.time()

	for i, record in ipairs(self.records) do
		if time - record.time > MSG_KEEP_TIME then
			table.insert(indexes, i)
		end
	end

	local i = 0
	while #indexes > 0 do
		i = table.remove(indexes, #indexes)
		table.remove(self.records, 1)
	end

	while #self.records > MSG_MAX do
		table.remove(self.records, 1)
	end
end

function MsgMgr:remove(id)
	local found = false

	for i, record in ipairs(self.records) do
		if record.id == id then
			table.remove(self.records, i)
			found = true
			break;
		end
	end

	if not found then
		return ERROR_CODE.LOGICAL_ERROR
	end

	unilight.debug("Succeed to remove a msg")
	return 0
end
