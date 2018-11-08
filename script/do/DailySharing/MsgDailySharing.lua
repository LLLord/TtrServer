
-- 获取每日分享配置信息
Net.CmdGetDailySharingInfoCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetDailySharingInfoCmd_S"
	local uid = laccount.Id
    local userInfo = UserInfo.GetUserInfoById(uid)
	local num = userInfo.dailySharing:GetDailySharingInfo()
	print("CmdGetDailySharingInfoCmd_C, uid="..uid..", num="..num)

	res["data"] = {
		resultCode 	= 0,
		desc 		= "成功",
		id 			= num,
	}
	return res
end


 --领取每日分享奖励
Net.CmdGetDailySharingRewardCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetDailySharingRewardCmd_S"
	local uid = laccount.Id
	local sharingId = cmd.data.id
	local userInfo = UserInfo.GetUserInfoById(uid)
	local  ret, desc, sharingId = userInfo.dailySharing:GetDailySharingReward(sharingId)
    print("CmdGetDailySharingRewardCmd_C, uid="..uid..", sharingId="..sharingId..", ret="..ret..", desc="..desc)

	--任务系统，任务完成情况
	local ask_userInfo = UserInfo.GetUserInfoById(uid)
	if ask_userInfo ~= nil then
		ask_userInfo.achieveTask:addProgress(TaskConditionEnum.SharedGameEvent, 1)
		ask_userInfo.dailyTask:addProgress(TaskConditionEnum.SharedGameEvent, 1)
	end

	res["data"] = {
		resultCode 	= ret,
		desc 		= desc,
		id 	= sharingId,
	}
	return res
end