function Net.CmdMsgPullCmd_C(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.MsgPullCmd_S"
	res["data"] = {
		resultCode = 0
	}

	local userInfo = UserInfo.GetUserInfoById(laccount.Id)

	res.data["records"] = userInfo.msgMgr.records

	return res
end

function Net.CmdMsgSkipCmd_C(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.MsgSkipCmd_S"
	res["data"] = {}

	if cmd.data == nil or cmd.data.id == nil then
		return ERROR_CODE.ARGUMENT_ERROR
	end

	res.data["id"] = cmd.data.id

	local userInfo = UserInfo.GetUserInfoById(laccount.Id)

	res.data["resultCode"] = userInfo.msgMgr:remove(cmd.data.id)

	return res
end
