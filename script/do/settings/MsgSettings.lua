function Net.CmdGetSettingsCmd_C(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetSettingsCmd_S"
	res["data"] = { resultCode = 0 }

	local userInfo = UserInfo.GetUserInfoById(laccount.Id)

	if userInfo == nil then
		res["data"].resultCode = ERROR_CODE.LOGICAL_ERROR
		return res
	end

	if userInfo.settings == nil then
		return res
	end

	res["data"].settings = userInfo.settings
	return res
end

function Net.CmdSaveSettingsCmd_C(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.SaveSettingsCmd_S"
	res["data"] = { resultCode = 0 }
	

	local userInfo = UserInfo.GetUserInfoById(laccount.Id)

	if userInfo == nil then
		res["data"].resultCode = ERROR_CODE.LOGICAL_ERROR
		return res
	end

	--open save?
	if cmd.data == nil or cmd.data.settings == nil then
		res["data"].resultCode = ERROR_CODE.ARGUMENT_ERROR
	end

	userInfo.settings = cmd.data.settings

	--暂时保存一份在好友系统里, 以后可能要做别的处理
	local friendData = FriendManager:GetOrNewFriendInfo(laccount.Id)
	friendData:SetUserSimpleData(userInfo.star, userInfo.gender, userInfo.settings.signature, userInfo.settings.area, userInfo.settings.horoscope)
	return res
end

