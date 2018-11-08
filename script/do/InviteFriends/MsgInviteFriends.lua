

-- //获取玩家邀请到的好友信息
Net.CmdGetInviteFriendInfoCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetInviteFriendInfoCmd_S"
	local uid = laccount.Id
	local code, desc, inviteFriendsInfo = InviteFriendsMgr.GetInviteFriendsInfo(uid)
	unilight.debug("InviteFriendsMgr.GetInviteFriendsInfo, uid="..uid..", end")

	res["data"] = {
		resultCode 	= code,
		desc 		= desc,
		data 	    = inviteFriendsInfo,
	}
	return res
end

 --领取 邀请好友 获得的奖励
Net.CmdGetInviteFriendRewardCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetInviteFriendRewardCmd_S"
	local uid = laccount.Id
	local friendUid = cmd.data.friendUid
	print("CmdGetInviteFriendRewardCmd_C, uid="..uid..", friendUid="..friendUid)
	local  ret, desc, rewardId = InviteFriendsMgr.GetInviteFriendReward(uid, friendUid)

	res["data"] = {
		resultCode 	= ret,
		desc 		= desc,
		rewardId 	= rewardId,
	}
	return res
end