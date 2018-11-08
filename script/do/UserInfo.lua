module('UserInfo', package.seeall) -- 用户信息

GlobalUserInfoMap = {} -- 玩家在线信息全局管理

--获取玩家的在线信息
function GetUserInfoById(uid)
	return GlobalUserInfoMap[uid]
end

function UpdateQqData(uid, head, name, sex)
	local userInfo = GetUserInfoById(uid)

	if userInfo ~= nil then
		userInfo.head = head
		userInfo.nickName = name
		userInfo.sex = sex
	end
end

function CreateTempUserInfo(uid)
	unilight.debug("Create new user info")

	local userInfo = {
		uid			= uid,
		nickName	= "测试员" .. uid,
		money		= GlobalConst.Initial_Gold,
		diamond		= GlobalConst.Initial_Diamond,
		star		= 0,
		settings	= {},
		sex			= 1,
		head		= "",
		firstLogin  = 1,--首次登陆
	}

	local world = World:new()
	world:init(userInfo)
	world:create()
	userInfo["world"] = world

	--日常任务数据
	local dailyTask = DailyTaskMgr:New()
	dailyTask:init(userInfo)
	userInfo["dailyTask"] = dailyTask

	--成就任务数据
	local achieveTask = AchieveTaskMgr:New()
	achieveTask:init(userInfo)
	userInfo["achieveTask"] = achieveTask

	--玩家商品
	local items = UserItems:new()
	items:init(userInfo)	
	userInfo["UserItems"] = items
	--玩家属性
	local props = UserProps:new()
	props:init(userInfo)
	userInfo["UserProps"] = props

	local msgMgr = MsgMgr:new()
	msgMgr:init(userInfo)
	msgMgr:createTemp()
	userInfo["msgMgr"] = msgMgr

	local mailMgr = MailMgr:new()
	mailMgr:init(userInfo)
	userInfo["mailMgr"] = mailMgr

	local dailySharing = DailySharing:new()
	dailySharing:init(userInfo)
	userInfo["dailySharing"] = dailySharing

	local collect = Collect:new()
	collect:init(userInfo)
	userInfo["collect"] = collect

	local dailyWelfare = DailyWelfare:new()
	dailyWelfare:init(userInfo)
	userInfo["dailyWelfare"] = dailyWelfare

    local dailyLogin = DailyLogin:new()
    dailyLogin:init(userInfo)
    userInfo["dailyLogin"] = dailyLogin

	return userInfo
end

function CreateUserByDb(uid, dbUser)
	unilight.debug("Get user info from DB")

	userInfo = {
		uid = uid,
		nickName = dbUser.nickName,
		money = dbUser.money,
		diamond = dbUser.diamond,
		star = dbUser.star or 0,
		head = dbUser.head or "",
		sex = dbUser.sex or 1,
		lastlogintime = dbUser.lastlogintime or 0,
		firstLogin = dbUser.firstLogin or 1,
	}
	userInfo["settings"] = dbUser.settings or {}
--玩家商品
	local items = UserItems:new()
	items:init(userInfo)	
	userInfo["UserItems"] = items
	if dbUser.useritems ~= nil then
		items:setDBTable(dbUser.useritems)
	end
	--玩家属性
	local props = UserProps:new()
	props:init(userInfo)
	userInfo["UserProps"] = props
	if dbUser.userprops ~= nil then
		props:setDBTable(dbUser.userprops)
	end

	local world = World:new()
	world:init(userInfo)

	if dbUser["world"] == nil then
		unilight.warn("Load user info from DB, but there is no world data")
		world:create()
	elseif world:loadFromDb(dbUser.world) ~= true then
		unilight.warn("Can load world data from DB")
	end

	userInfo["world"] = world

	--[Msg
	-- Temporarilly use userinfo db
	local msgMgr = MsgMgr:new()
	msgMgr:init(userInfo)

	if dbUser["msg"] == nil then
		msgMgr:createTemp()
	else
		msgMgr:loadFromDb(dbUser.msg)
		msgMgr:clean()
	end

	userInfo["msgMgr"] = msgMgr
	--]
	
	--Not to load data here
	local mailMgr = MailMgr:new()
	mailMgr:init(userInfo)
	userInfo["mailMgr"] = mailMgr

	--日常任务数据
	local dailyTask = DailyTaskMgr:New()
	dailyTask:init(userInfo)
	userInfo["dailyTask"] = dailyTask

	if dbUser.dailyTask ~= nil then
		dailyTask:SetDBTable(dbUser.dailyTask)
	end
	

	--成就任务数据
	local achieveTask = AchieveTaskMgr:New()
	achieveTask:init(userInfo)
	userInfo["achieveTask"] = achieveTask
	
	if dbUser.achieveTask ~= nil then
		achieveTask:SetDBTable(dbUser.achieveTask)
	end

	local dailySharing = DailySharing:new()
	dailySharing:init(userInfo)
	if dbUser["dailySharing"] == nil then
		unilight.warn("Load user info from DB, but there is no dailySharing data")
		--DailySharing:create()
	elseif dailySharing:loadFromDb(dbUser.dailySharing) ~= true then
		unilight.warn("Can load dailySharing data from DB")
	end
	userInfo["dailySharing"] = dailySharing

	local collect = Collect:new()
	collect:init(userInfo)
	if dbUser["collect"] == nil then
		unilight.warn("Load user info from DB, but there is no collect data")
	elseif collect:loadFromDb(dbUser.collect) ~= true then
		unilight.warn("Can load collect data from DB")
	end
	userInfo["collect"] = collect

	local dailyWelfare = DailyWelfare:new()
	dailyWelfare:init(userInfo)
	if dailyWelfare:loadFromDb(dbUser.dailyWelfare) ~= true then
		unilight.warn("Can not load dailyWelfare data from DB")
	end
	userInfo["dailyWelfare"] = dailyWelfare

    local dailyLogin = DailyLogin:new()
    dailyLogin:init(userInfo)
    if dbUser["dailyLogin"] == nil then
        unilight.warn("Load user info from DB, but there is no dailyLogin data")
    elseif dailyLogin:loadFromDb(dbUser.dailyLogin) ~= true then
        unilight.warn("Can load dailyLogin data from DB")
    end
    userInfo["dailyLogin"] = dailyLogin


    	if userInfo.star == 0 then
		userInfo.star = world:recalcStar()
	end
	
	return userInfo
end

function DealOfflinePrize(userinfo)
	if userinfo == nil or userinfo.lastlogintime == nil then
		return
	end
	local time = os.time()
	time = time - userinfo.lastlogintime
	time = math.min(time, GlobalConst.Max_OffLine_Time)	

	local earning = math.floor(userinfo.world:earn() * time * GlobalConst.OffLine_Factor * (1 + userinfo.UserProps:getUserProp("pOfflineGoldAddRatio")))
	UserInfo.AddUserMoney(userinfo, static_const.Static_MoneyType_Gold, earning)
	local res = { }
	res["do"] = "Cmd.ReqGetCardDayPrizeCmd_CS"
	res["data"] = {
		offlinetime = time,
		earning = earning,
		desc = "离线奖励返回",		
	}	
	unilight.response(userinfo.laccount, res)
end
function Update()
	for k,userInfo in pairs(GlobalUserInfoMap) do
		userInfo.world:update()
		--SendUserMoney(userInfo)
	end
end

function GetClientData(userInfo)
	local userInfoData = {
		uid = userInfo.uid,
		nickName = userInfo.nickName,
		money = userInfo.money,
		diamond = userInfo.diamond,
		star = userInfo.star,
		head = userInfo.head,
		sex = userInfo.sex,
		world = userInfo.world:sn(),
		dailySharing = userInfo.dailySharing:GetData(),
		collect = userInfo.collect:GetData(),
	}

	return userInfoData
end

function GetServerData(userInfo)
	local userInfoData = {
		uid = userInfo.uid,
		nickName = userInfo.nickName,
		money = userInfo.money,
		diamond = userInfo.diamond,
		star = userInfo.star,
		head = userInfo.head,
		sex = userInfo.sex,
		lastlogintime = os.time(),
		world = userInfo.world:sn(),
		settings = userInfo.settings,
		msg = userInfo.msgMgr:sn(),
		dailySharing = userInfo.dailySharing:GetData(),
		collect = userInfo.collect:GetData(),
		dailyTask = userInfo.dailyTask:GetDBTable(),
		achieveTask = userInfo.achieveTask:GetDBTable(),
		dailyWelfare = userInfo.dailyWelfare:GetData(),
		useritems = userInfo.UserItems:GetDBTable(),
		userprops = userInfo.UserProps:GetDBTable(),
        dailyLogin = userInfo.dailyLogin:GetData(),
		firstLogin = 1, -- add for test
	}

	return userInfoData
end

function Connected(uid)
	
end

function Disconnected(uid)
	unilight.info("account_disconnect:" .. uid)

	FriendManager:UserLogoutFriend(uid)

	local userInfo = GetUserInfoById(uid)

	if userInfo == nil then
		unilight.warn("User is nil")
		return
	end

	unilight.savedata("userinfo", GetServerData(userInfo))

	userInfo.mailMgr:saveToDb()

	GlobalUserInfoMap[uid] = nil
end

--------------------------------------------------
--货币
function GetUserMoneyByUid(uid, moneytype)
	moneytype = tonumber(moneytype)
	local userinfo = UserInfo.GetUserInfoById(uid)
	if userinfo == nil then
		return 0
	end
	if moneytype == static_const.Static_MoneyType_Diamond then
		return userinfo.diamond
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		return userinfo.money
	end
	return 0
end
function CheckUserMoneyByUid(uid, moneytype, moneynum)
	moneytype = tonumber(moneytype)
	moneynum = tonumber(moneynum)
	local userinfo = UserInfo.GetUserInfoById(uid)
	if userinfo == nil then
		return false
	end
	if moneytype == static_const.Static_MoneyType_Diamond then
		return userinfo.diamond >= moneynum
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		return userinfo.money >= moneynum
	end
	return true
end
function AddUserMoneyByUid(uid, moneytype, moneynum)
	moneytype = tonumber(moneytype)
	moneynum = tonumber(moneynum)
	local userinfo = UserInfo.GetUserInfoById(uid)
	if userinfo == nil then
		return
	end
	if moneytype == static_const.Static_MoneyType_Diamond then
		userinfo.diamond = userinfo.diamond + moneynum
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		userinfo.money = userinfo.money + moneynum
		RankListMgr:UpdateRankNode(RankListMgr.rank_type_money, uid, userinfo.money)
		local friendInfo = FriendManager:GetFriendInfo(userinfo.uid)
		if friendInfo ~= nil then
			friendInfo.simpleData.money = userinfo.money
		end
	end

	--同步下	
	SendUserMoney(userinfo)	
	return moneynum
end

function SubUserMoneyByUid(uid, moneytype, moneynum)
	moneytype = tonumber(moneytype)
	moneynum = tonumber(moneynum)
	local userinfo = UserInfo.GetUserInfoById(uid)
	if userinfo == nil then
		return 0
	end
	local num = 0
	if moneytype == static_const.Static_MoneyType_Diamond then
		if userinfo.diamond > moneynum then
			userinfo.diamond = userinfo.diamond - moneynum
			num = moneynum
		end
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		if userinfo.money > moneynum then
			userinfo.money = userinfo.money - moneynum
			RankListMgr:UpdateRankNode(RankListMgr.rank_type_money, uid, userinfo.money)
			local friendInfo = FriendManager:GetFriendInfo(userinfo.uid)
			if friendInfo ~= nil then
				friendInfo.simpleData.money = userinfo.money
			end
			num = moneynum
			--任务系统，任务完成情况
			userinfo.achieveTask:addProgress(TaskConditionEnum.CostDiamondEvent,moneynum)
			userinfo.dailyTask:addProgress(TaskConditionEnum.CostDiamondEvent, moneynum)
		end
	end
	if num then
		--同步下	
		SendUserMoney(userinfo)	
	end
	return num

end
function GetUserMoney(userinfo, moneytype)
	moneytype = tonumber(moneytype)
	if userinfo == nil then
		return 0
	end
	if moneytype == static_const.Static_MoneyType_Diamond then
		return userinfo.diamond
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		return userinfo.money
	end
	return 0
end
function CheckUserMoney(userinfo, moneytype, moneynum)
	moneytype = tonumber(moneytype)
	moneynum = tonumber(moneynum)
	if userinfo == nil then
		return
	end
	if moneytype == static_const.Static_MoneyType_Diamond then
		return userinfo.diamond >= moneynum
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		return userinfo.money >= moneynum
	end
	return true
end
function AddUserMoney(userinfo, moneytype, moneynum)
	moneytype = tonumber(moneytype)
	moneynum = tonumber(moneynum)
	if userinfo == nil then return 0 end
	unilight.debug("begin, AddUserMoney-001, uid="..userinfo.uid..", moneytype="..moneytype..", moneyNum="..moneynum)
	if moneytype == static_const.Static_MoneyType_Diamond then
		userinfo.diamond = userinfo.diamond + moneynum
		unilight.debug("add, uid="..userinfo.uid..", diamond="..userinfo.diamond..", moneyNum="..moneynum)
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		unilight.debug("add, uid="..userinfo.uid..", money="..userinfo.money..", moneyNum="..moneynum)
		userinfo.money = userinfo.money + moneynum
		RankListMgr:UpdateRankNode(RankListMgr.rank_type_money, userinfo.uid, userinfo.money)
		local friendInfo = FriendManager:GetFriendInfo(userinfo.uid)
		if friendInfo ~= nil then
			friendInfo.simpleData.money = userinfo.money
		end
	end
	--同步下	
	SendUserMoney(userinfo)
	unilight.debug("end, AddUserMoney-009, uid="..userinfo.uid..", money="..userinfo.money..", diamond="..userinfo.diamond)

	return moneynum

end
function SubUserMoney(userinfo, moneytype, moneynum)
	moneytype = tonumber(moneytype)
	moneynum = tonumber(moneynum)
	if userinfo == nil then
		return 0
	end
	local num = 0
	if moneytype == static_const.Static_MoneyType_Diamond then
		if (userinfo.diamond) > (moneynum) then
			userinfo.diamond = userinfo.diamond - moneynum
			num = moneynum
		end
	end
	if moneytype == static_const.Static_MoneyType_Gold then
		if userinfo.money > moneynum then
			userinfo.money = userinfo.money - moneynum
			RankListMgr:UpdateRankNode(RankListMgr.rank_type_money, userinfo.uid, userinfo.money)
			local friendInfo = FriendManager:GetFriendInfo(userinfo.uid)
			if friendInfo ~= nil then
				friendInfo.simpleData.money = userinfo.money
			end
			num = moneynum
			--任务系统，任务完成情况
			userinfo.achieveTask:addProgress(TaskConditionEnum.CostDiamondEvent, moneynum)
			userinfo.dailyTask:addProgress(TaskConditionEnum.CostDiamondEvent, moneynum)
		end
	end
	unilight.debug("end, SubUserMoney-002, uid="..userinfo.uid..", moneytype="..moneytype..", moneyNum="..moneynum ..",num:" .. num)
	if num then
		--同步下	
		SendUserMoney(userinfo)	
	end
	return num
end

function SendUserMoney(userinfo)
	unilight.debug("SendUserMoney-001")
	if userinfo == nil then
		return 0
	end
	local res = { }
	res["do"] = "Cmd.SendUserMoneyCmd_S"
	
	local diamond = userinfo.diamond
	local money = userinfo.money
	res["data"] = {
		diamond = userinfo.diamond,
		gold = userinfo.money,
		desc = "玩家货币返回",
	}
	unilight.response(userinfo.laccount, res)
	unilight.debug("SendUserMoney-002")
	return res
end
------------------------------------------------------
