
-- 领取分享奖励
Net.CmdGetShareRewardCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd. GetShareRewardCmd_S"
	if cmd.data == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local uid = laccount.Id

	local ret, desc, rewardTimes, rewardData = ShareMgr.GetShareReward(uid)
	res["data"] = {
		resultCode = ret,
		desc = desc,
		rewardTimes = rewardTimes, 
		rewardData = rewardData,	
	}
	return res
end