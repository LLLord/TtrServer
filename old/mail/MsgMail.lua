-- 获取邮件列表
Net.CmdGetListMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetListMailCmd_S"
	local uid = laccount.Id
	local index = cmd.data.index or 1
    local mailtype = cmd.data.mailtype
	local  ret, desc, userMailInfo, userNewsInfo = MailMgr.GetListUserMail(uid, index, mailtype)
	
	if ret ~= 0 and RoomInfo and RoomInfo.SendFailToUser and type(RoomInfo.SendFailToUser) == "function" then
		RoomInfo.SendFailToUser(desc,laccount)
	end
	res["data"] = {
		resultCode 	= ret, 
		desc 		= desc, 
		mailInfo 	= userMailInfo,
		newsInfo    = userNewsInfo,
	}
	return res
end

-- 查看邮件 
Net.CmdReadMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ReadMailCmd_S"
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.id == nil then
		res["data"] = {
			resultCode 	= 1, 
			desc 		= "参数有误", 
		}
		return res
	end

	local  ret, desc, mailInfo = MailMgr.ReadMail(uid, cmd.data.id)
	if ret ~= 0 and RoomInfo and RoomInfo.SendFailToUser and type(RoomInfo.SendFailToUser) == "function" then
		RoomInfo.SendFailToUser(desc,laccount)
	end
	res["data"] = {
		resultCode 	= ret, 
		desc 		= desc,  
		mailInfo 	= mailInfo,
	}
	return res
end

--[[ 删除邮件
Net.CmdDeleteMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.DeleteMailCmd_S"
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.ids == nil or table.len(cmd.data.ids) == 0 then
		res["data"] = {
			resultCode 	= 1, 
			desc 		= "参数有误", 
		}
		return res
	end

	local  ret, desc = MailMgr.DeleteUserMail(uid, cmd.data.ids)
	if ret ~= 0 and RoomInfo and RoomInfo.SendFailToUser and type(RoomInfo.SendFailToUser) == "function" then
		RoomInfo.SendFailToUser(desc,laccount)
	end
	res["data"] = {
		resultCode 	= ret, 
		desc 		= desc,
		ids 		= cmd.data.ids
	}
	return res
end]]

--领取指定邮件内的奖励
Net.CmdGetMailRewardCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetMailRewardCmd_S"
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.id == nil then
		res["data"] = {
			resultCode 	= 1, 
			desc 		= "参数有误", 
		}
		return res
	end

	local  ret, desc, userMailInfo = MailMgr.GetMailReward(uid, cmd.data.id)
	if ret ~= 0 and RoomInfo and RoomInfo.SendFailToUser and type(RoomInfo.SendFailToUser) == "function" then
		RoomInfo.SendFailToUser(desc,laccount)
	end
	res["data"] = {
		resultCode 	= ret, 
		desc 		= desc, 
		mailInfo 	= userMailInfo,
	}
	return res
end

-- 邮件批量操作
Net.CmdBulkOperationMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.BulkOperationMailCmd_S"
	local uid = laccount.Id
	--optype:1 全部处理  2 全部删除
	if cmd.data == nil or cmd.data.opType == nil then
		res["data"] = {
			resultCode 	= 1, 
			desc 		= "参数有误", 
		}
		return res
	end

	local  ret, desc, resData = MailMgr.BulkOperationMail(uid, cmd.data.opType, cmd.data.ids)
	if ret ~= 0 and RoomInfo and RoomInfo.SendFailToUser and type(RoomInfo.SendFailToUser) == "function" then
		RoomInfo.SendFailToUser(desc,laccount)
	end
	res["data"] = {
		resultCode 	= ret, 
		desc 		= desc, 
		opType 		= cmd.data.opType,
		attachment 	= resData,
	}
	return res
end
