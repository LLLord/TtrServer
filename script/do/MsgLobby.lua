-- 登录获取个人信息
Net.CmdUserInfoSynLobbyCmd_C = function(cmd, laccount)
	unilight.debug("收到获取个人信息")

	local uid 		= laccount.Id
	local lobbyId 	= cmd.data.lobbyId
    local subPlatid = cmd.data.subPlatid
	local userdata 	= nil
	local fm = nil
	--local head = cmd.data.head
	--local name = cmd.data.name
	--local sex = cmd.data.sex
	
	--临时注释掉上面的代码，模拟用户的数据

	local userInfo = UserInfo.GetUserInfoById(uid)

	local isFirstLogin = false
	if userInfo == nil then
		local dbUser = unilight.getdata("userinfo", uid)

		if dbUser == nil then
			userInfo = UserInfo.CreateTempUserInfo(uid)
			isFirstLogin = true
		else
			userInfo = UserInfo.CreateUserByDb(uid, dbUser)
		end

		UserInfo.GlobalUserInfoMap[uid] = userInfo
	end

	--有可能需要重置每日任务数据
	userInfo.dailyTask:Reset()
	userInfo.achieveTask:LoadConfig()

	--userInfo.nickName = name or userInfo.nickName
	--userInfo.head = head or userInfo.head
	--userInfo.sex = sex or userInfo.sex
	userInfo.laccount = laccount
	unilight.debug("userInfo.dailyTask:addProgress")
	userInfo.dailyTask:addProgress(TaskConditionEnum.LoginEvent, 1)

	--玩家好友数据创建或登录
	local friendData = FriendManager:UserLoginFriend(uid)
	local travelData = friendData:GetUserTravel()
	--同步玩家数据到好友数据
	friendData:SetStar(userInfo.star)
	friendData:SetMoney(userInfo.money)
	--friendData:SetHead(userInfo.head)
	--friendData:SetName(userInfo.nickName)
	--friendData:SetSex(userInfo.sex)
	--只同步客户端需要的数据，UserInfo下面存有服务器需要的数据

	userInfo.dailyLogin:Login()
	
	if isFirstLogin == true then
		userInfo.achieveTask:addProgress(TaskConditionEnum.OpenMapEvent, 1)
		userInfo.dailyTask:addProgress(TaskConditionEnum.OpenMapEvent, 1)
	end

	local res = {}
	res["do"] = "Cmd.UserInfoSynLobbyCmd_S"
	res["data"] = {
		resultCode = 0,
		userInfo = UserInfo.GetClientData(userInfo),
		is_first_login = isFirstLogin,
		shield_count = travelData:GetShieldCount()
	}
	--离线数据
	UserInfo.DealOfflinePrize(userInfo)

	return res
end

function Net.CmdPing_C(cmd, laccount)
	--[
	local res = {}
	res["do"] = "Cmd.Ping_S"
	res["data"] = {
		resultCode = 0,
	}

	--local userInfo = UserInfo.GetUserInfoById(laccount.Id)
	--message.give(11947586, userInfo, MsgTypeEnum.FriendApply)

	return res
	--]
end
