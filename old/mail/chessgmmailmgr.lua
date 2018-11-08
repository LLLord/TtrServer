module("ChessGmMailMgr", package.seeall)

-- 初始化一个全局唯一的 邮件id
function InitEmailId()
	local info = {
		_id 	= 1,
		emailid = 100000,	-- 初始化10w 因为以前全局唯一由平台控制 避免重复
	}
	unilight.savedata("globalemailid", info)
	return info 
end

-- 获取一个全局唯一的 邮件id
GlobalMailId = nil
function GetEmailId()
	local info = GlobalMailId or unilight.getdata("globalemailid", 1)
	if info == nil then
		info = InitEmailId()
	end
	info.emailid = info.emailid + 1
	unilight.savedata("globalemailid", info)
    GlobalMailId = info
	return info.emailid
end

-- 新增 全局邮件 gm工具添加后 这里主动添加
function AddGlobalMail(mailInfo)
	if mailInfo == nil then
		return 1, "邮件信息为空 发送邮件失败"
	end

	-- 全局唯一的邮件id 现在自己维护
	local emailId = GetEmailId()
	mailInfo.id = emailId

	-- 所有gm过来的邮件 均存档
	if mailInfo.recordtime == nil then
		mailInfo.recordtime = os.time()
	end
    mailInfo.overtime = 1
    -- 新增的时间范围，玩家在范围内，则给推送邮件
    mailInfo.starttime = mailInfo.starttime or os.time()
    if mailInfo.starttime == nil or mailInfo.starttime == 0 or mailInfo.endtime == nil or mailInfo.endtime == 0 then
        mailInfo.overtime = 0
        mailInfo.endtime = 9999999999
    end
    -- 我们这里只把全局邮件存起来，个人邮件直接存到个人表里面不用考虑玩家是否在线
    if mailInfo.type == 0 then
        MailMgr.UpdateMailToUserMailDataMail(mailInfo)
    else
        unilight.savedata("globalmailinfo", mailInfo)
    end

	-- 每次添加邮件的时候 主动更新一下当前在线玩家的邮件
	if type(MailMgr.UpdateUserMail) == "function" then
		local userInfo = go.accountmgr.GetOnlineList()
		if mailInfo.type == 0 then
            --[[
			-- 单人邮件 则检测该玩家是否在线 在线 则刷一下
			for i=1,#userInfo do
				if userInfo[i] == mailInfo.charid then
					MailMgr.UpdateUserMail(mailInfo.charid)
					break
				end
			end
            ]]
		else
			-- 多人邮件 所有在线玩家均刷新一下(这里如果有性能问题请切到其他进程去进行类似操作)
			local userInfo = go.accountmgr.GetOnlineList()
			for i=1,#userInfo do
				MailMgr.UpdateUserMail(userInfo[i])
            end
		end
	end

	return 0, "发送邮件成功"
end
