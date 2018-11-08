module('ShareMgr', package.seeall)
-- 每日分享相关  


local REWARD_LIMIT = 5
local REWARD_DIAMOND = 10

-- 领取任务奖励
function GetShareReward(uid)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local shareNum = userInfo.shareNum
	if shareNum + 1 >= REWARD_LIMIT then
		return 1, "分享已达上限，没有奖励"
	else
		--加钻石
		addDiamond(REWARD_DIAMOND)
		userInfo.shareNum = userInfo.shareNum + 1

		local rewardData = {}
		local rewardInfo = {
			rewardType = 1,
			rewardNum = REWARD_DIAMOND,
	    }
	    table.insert(rewardData, rewardInfo)
	    return 0, "领取任务奖励成功", shareNum, rewardData
	end
end


--每天零点更新分享次数
function UpdataRewardNum()
	userInfo.shareNum = 0
end



