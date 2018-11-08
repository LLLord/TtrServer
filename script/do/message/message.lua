module("message", package.seeall)

	--[[
	功能：产生一条消息，记录在对应的玩家下
	参数：
		uid		:number,			对应玩家的UID
		who		:UserInfo,			自身玩家的信息
		msgType	:MsgTypeEnum,		消息类型
		args	:字符串数组,		消息参数
	实例：
		give(laccount.Id, userInfo, MsgTypeEnum.FriendApply)
	--]]
function give(uid, who, msgType, args)
	local userInfo = UserInfo.GetUserInfoById(uid)

	local l_who = {
		uid = who.uid,
		male = who.sex,
		nickName = who.nickName,
		star = who.star,
	}

	if userInfo == nil then
		save(uid, l_who, msgType, args)
	else
		userInfo.msgMgr:addNew(l_who, msgType, args)
	end
end

function save(uid, who, msgType, args)
	local data = unilight.getfield("userinfo", uid, "msg")
	
	if data == nil then 
		unilight.debug("Can not get field msg about uid:" .. uid)
		return
	end

	data.id = data.id + 1
	
	if data.records == nil then
		unilight.debug("Records of msg is nil, UID:" .. uid)
		data.records = {}
	end

	if #data.records == MSG_MAX then
		table.remove(data.records, 1)
	end

	local msg = create(data.id, who, msgType, args)
	table.insert(data.records, msg)

	unilight.savefield("userinfo", uid, "msg", data)
end

function create(id, who, msgType, args)
	local msg = {
		id = id,
		time = os.time(),
		msgType = msgType,
		arguments = args,
		who = who,
	}

	return msg
end
