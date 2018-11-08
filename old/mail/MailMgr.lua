module('MailMgr', package.seeall)
-- 邮件系统

-- 邮件类型type 0消息 1邮件

-- 邮件状态

local MAIL_LIMIT = 100
local NEWS_LIMIT = 50
local MAIL_KEEP = 7 * 24
local NEWS_KEEP = 24

ENUM_MAIL_STATE = {
    UNREAD = 1;         -- 未读
    --READ_HAS_ITEM = 2;  -- 已读,但还有未领取的东西
    READ_OVER = 3;       -- 已读,且没有需要领取的东西
}

-- 初始化 个人邮件 相关存储
function InitUserMail(uid)
	local userMailData = {
		uid 		= uid,	-- 玩家id
		maildata 	= {},	-- 当前邮件数据
		lastid		= 0,	-- 最新同步的邮件id
	}
	SaveUserMail(userMailData)
	return userMailData
end

-- 获取邮件数据
function GetUserMail(uid)
	local userMailData = unilight.getdata("usermailinfo", uid)
	if userMailData == nil then
		userMailData = InitUserMail(uid)
	end
	return userMailData
end

-- 更新玩家邮件相关数据 
function UpdateUserMail(uid, userData)
	-- 如果获取不到laccount则此次不更新邮件 (如果登录了推广员系统则在线玩家列表中存在该玩家 所以可能会通过检测 但是其获取不到laccount)
	local laccount = go.roomusermgr.GetRoomUserById(uid)
	if laccount == nil then
		return 
	end
	userData = userData or unilight.getdata("userinfo", uid)
    local curTime = os.time()
	local mailTime = curTime - 7*24*60*60
	local newsTime = curTime - 24*60*60
    -- 如果是新注册用户，则只推送注册时间以后的邮件
    if userData.status.registertimestamp > mailTime then
        mailTime = userData.status.registertimestamp
    end
    if userData.status.registertimestamp > newsTime then
        newsTime = userData.status.registertimestamp
    end
	local userMailData = GetUserMail(uid)
	-- 获取公共邮件中的 符合要求的 前5封邮件
	local orderby 	= unilight.desc("id")
	local filter1 	= unilight.a(unilight.eq("type", 0), unilight.eq("charid", uid))	-- 单人邮件 且 对象是当前uid
	local filter2	= unilight.o(unilight.eq("type", 1), filter1)						-- 群体邮件 或者 是 （单人邮件 且 对象是当前uid）
	local filter3	= unilight.o(unilight.ge("recordtime", mailTime),unilight.eq("overtime", 1))						-- 群体邮件 或者 是 （单人邮件 且 对象是当前uid）
	local filter4 	= unilight.a(filter3, filter2)
	local filter5 	= unilight.a(unilight.gt("id", userMailData.lastid), filter4)		-- 且必须 id 大于 该玩家邮件的lastid
    local filter6 = unilight.a(unilight.le("starttime", curTime), unilight.ge("endtime", curTime))
    local filter = unilight.a(filter6, filter5)
	local info = unilight.chainResponseSequence(unilight.startChain().Table("globalmailinfo").Filter(filter))
	local len = table.len(info)
	-- 存在新邮件需要更新
	if len > 0 then
		table.sort( info, function(a, b)
			if a.id < b.id then
				return true
			end
        return false
		end )
		-- 从老到新 一个个填充到玩家自身的邮件列表中
		for i=len,1,-1 do
			local mailInfo = {
				id 			= info[i].id,			-- 该邮件id
				--subject		= info[i].subject,		-- 标题
				content		= info[i].content,		-- 内容
				recordtime 	= info[i].recordtime,	-- 发送时间
				attachment 	= info[i].attachment,	-- 附件
				state 		= ENUM_MAIL_STATE.UNREAD,-- 未读状态
				--sendname 	= info[i].sendname or "系统",		-- 发送者
				--starttime	= info[i].starttime,
				--endtime		= info[i].endtime,
				--savetime 	= os.time(),
                mailtype    = info[i].mailtype or 0,     -- 邮件类型 0消息 1邮件
                --outline     = info[i].outline,      -- 概要
			}
			table.insert(userMailData.maildata, mailInfo)
			-- 更新 最新一条邮件的id
			if info[i].id > userMailData.lastid then
				userMailData.lastid = info[i].id
			end
		end

		-- 只保留最新的5条
		-- if table.len(userMailData.maildata) > 5 then
		-- 	userMailData.maildata = table.slice(userMailData.maildata, table.len(userMailData.maildata)-4, table.len(userMailData.maildata))
		-- end

	end

    --将过期的邮件清除掉
    local mailIds = {}
    for i,v in ipairs(userMailData.maildata) do
    	if v.mailtype == 0 then
        	if v.recordtime < newsTime then
            	table.insert(mailIds, v.id)
        	end
        elseif v.mailtype == 1 then
        	if v.recordtime < mailTime then
            	table.insert(mailIds, v.id)
        	end
        end
    end
    if table.empty(mailIds) == false then 
        local remove = {}
        -- 遍历需要删除的所有邮件id
        for i,v in ipairs(mailIds) do
            remove[v] = true
        end
        local bOk = nil
        -- 遍历该玩家的邮件列表
        local maildata = {}
        for i,v in ipairs(userMailData.maildata) do
            if remove[v.id] ~= true then
                table.insert(maildata, v)
            end
        end

        -- 确实删除了 某些邮件
        if table.len(maildata) < table.len(userMailData.maildata) then
            userMailData.maildata = maildata
        end
    end

    SaveUserMail(userMailData)

    -- 存在未读邮件则 主动推送一下给前端 提示小红点
    local isSend = false
	for i,v in ipairs(userMailData.maildata) do
		if v.state == ENUM_MAIL_STATE.UNREAD then
			isSend = true
			break
		end
	end
	if isSend then
        if CheckIsMatchLobby and CheckIsMatchLobby() then
            RedMsgPoint.UpdateRedPointMatch(uid, 1, 1, userData)
		elseif RedMsgPoint and RedMsgPoint.AddRedPoint and type(RedMsgPoint.AddRedPoint) == "function" then
			RedMsgPoint.AddRedPoint(userData, RedMsgPoint.ENUM_REDPOINT.Task_NewMail)
		else
			local res = {}
			res["do"] 	= "Cmd.NewMailCmd_Brd"
			res["data"] = {}
			unilight.success(laccount, res)
		end
	end	

	--TODO:消息提示红点到时候写一个统一的接口
end

-- 更新玩家新邮件到个人邮件数据库中
function UpdateMailToUserMailDataMail(mailInfo)
    local uid = mailInfo.charid
	local userData
    if UserInfo and UserInfo.GetUserDataById then
        userData = UserInfo.GetUserDataById(uid)
    else
        userData = unilight.getdata("userinfo", uid)
    end
    local curTime = os.time()
	local userMailData = GetUserMail(uid)
    local data = {
        id = mailInfo.id,
        --subject = mailInfo.subject,
        content = mailInfo.content,
        recordtime = mailInfo.recordtime,
        attachment = mailInfo.attachment,
        state = ENUM_MAIL_STATE.UNREAD,
        --sendname = mailInfo.sendname or "系统",
        --starttime = mailInfo.starttime,
        --endtime = mailInfo.endtime,
        --savetime = curTime,
        mailtype = mailInfo.mailtype or 0, -- 新增字段：邮件类型 0：系统 1：好友
        --outline = mailInfo.outline,
    }
    table.insert(userMailData.maildata, data)

    --将过期的邮件清除掉
	local mailTime = os.time() - 7*24*60*60
	local newsTime = os.time() - 24*60*60
    local mailIds = {}
    for i,v in ipairs(userMailData.maildata) do
    	if v.mailtype == 0 then
        	if v.recordtime < newsTime then
            	table.insert(mailIds, v.id)
        	end
        elseif v.mailtype == 1 then
        	if v.recordtime < mailTime then
            	table.insert(mailIds, v.id)
        	end
        end
    end
    if table.empty(mailIds) == false then
        local remove = {}
        -- 遍历需要删除的所有邮件id
        for i,v in ipairs(mailIds) do
            remove[v] = true
        end
        local bOk = nil
        -- 遍历该玩家的邮件列表
        local maildata = {}
        for i,v in ipairs(userMailData.maildata) do
            if remove[v.id] ~= true then
                table.insert(maildata, v)
            end
        end

        -- 确实删除了 某些邮件了
        if table.len(maildata) < table.len(userMailData.maildata) then
            userMailData.maildata = maildata
        end
    end

    --列表已满删除最老的邮件
    local mailData = {}
    local newsData = {}
    for i,v in pairs (userMailData.maildata) do
    	if v.mailtype == 0 then
    		table.insert(newsData, v.id)
    	elseif v.mailtype == 1 then
    		table.insert(mailData, v.id)
    	end
    end
    if table.empty(mailData) == false and table.len(mailData) > MAIL_LIMIT then 
        local mailremove = {}
        -- 遍历需要删除的所有邮件id
        local len = table.len(mailData) - MAIL_LIMIT 
        for i = 0,i < len in ipairs(mailData) do
            mailremove[v] = true
        end
    end
    if table.empty(newsData) == false and table.len(newsData) > NEWS_LIMIT then 
        local newsremove = {}
        -- 遍历需要删除的所有邮件id
        local len = table.len(newsData) - news_LIMIT 
        for i = 0,i < len in ipairs(newsData) do
           newsremove[v] = true
        end
    end

    for i,v in ipairs(userMailData.maildata) do
        if remove[v.id] ~= true then
            table.insert(maildata, v)
        end
    end

    if table.len(maildata) < table.len(userMailData.maildata) then
        userMailData.maildata = maildata
    end

    SaveUserMail(userMailData)

    -- 存在未读邮件则 主动推送一下给前端 提示小红点
    local isSend = false
	for i,v in ipairs(userMailData.maildata) do
		if v.state == ENUM_MAIL_STATE.UNREAD then
			isSend = true
			break
		end
	end
	if isSend then
        if CheckIsMatchLobby and CheckIsMatchLobby() then
            RedMsgPoint.UpdateRedPointMatch(uid, 1, 1, userData)
		elseif RedMsgPoint and RedMsgPoint.AddRedPoint and type(RedMsgPoint.AddRedPoint) == "function" then
			RedMsgPoint.AddRedPoint(userData, RedMsgPoint.ENUM_REDPOINT.Task_NewMail)
		else
			local res = {}
			res["do"] 	= "Cmd.NewMailCmd_Brd"
			res["data"] = {}
			unilight.success(laccount, res)
		end
	end
end

-- 存档
function SaveUserMail(userMailData)
	unilight.savedata("usermailinfo", userMailData)
end

-- 通过邮件存档数据 获取邮件信息
function GetMailInfoByData(mailData)
	local mailInfo = {
		id  		= mailData.id, -- 邮件id
		--subject 	= mailData.subject, -- 标题
		content 	= mailData.content, -- 内容
		stamp 		= mailData.recordtime, -- 时间戳
		state 		= mailData.state, -- 状态
		attachment 	= mailData.attachment, -- 附件
		--sendName 	= mailData.sendname or "系统",
        mailtype    = mailData.mailtype or 0,
        --outline     = mailData.outline,
        goto        = mailData.goto,
	}
    --[[if mailInfo.outline == nil then
        if mailInfo.attachment then
            if mailInfo.state == READ_OVER then
                mailInfo.outline = "奖励已领取"
            else
                mailInfo.outline = "奖励已发放请领取"
            end
        else
            mailInfo.outline = "详情请点击查看"
        end
    end]]
	return mailInfo
end

-- 获取邮件列表
function GetListUserMail(uid, index, mailtype)
	local userMailData = GetUserMail(uid)

	local userMailInfo = {}
	local userNewsInfo = {}
    local mailData = {}
    local newsData = {}
    for i, v in ipairs(userMailData.maildata) do
        if v.mailtype == 0 then
            table.insert(mailData, v)
        elseif v.mailtype == 1 then
        	table.insert(userMailInfo, v)
        end
    end

    for i,v in pairs(mailData) do
    	if v.goto == 1 then
    		table.insert(userNewsInfo,v)
    	end
    end
    for i,v in pairs(mailData) do
    	if v.goto == 0 then
    		table.insert(userNewsInfo,v)
    	end
    end

	--[[邮件数据按时间顺序。可跳转排在上面
    local function checkSort(a, b)
        if CheckIsHaoCaiLobby and CheckIsHaoCaiLobby() then
            if a.state ~= ENUM_MAIL_STATE.READ_HAS_ITEM and b.state == ENUM_MAIL_STATE.READ_HAS_ITEM then
                return true
            end
            if b.state ~= ENUM_MAIL_STATE.READ_HAS_ITEM and a.state == ENUM_MAIL_STATE.READ_HAS_ITEM then
                return false
            end
            if a.state ~= ENUM_MAIL_STATE.UNREAD and b.state == ENUM_MAIL_STATE.UNREAD then
                return true
            end
            if b.state ~= ENUM_MAIL_STATE.UNREAD and a.state == ENUM_MAIL_STATE.UNREAD then
                return false
            end
        end
		return a.id < b.id
    end
    local len = table.len(mailData)
    for i = 1, len do
        for j = i, len do
            if checkSort(mailData[i], mailData[j]) then
                mailData[i], mailData[j] = mailData[j], mailData[i]
            end
        end
    end
	local perCount = 60
    local curTime = os.time()
	for i=(index-1)*perCount+1,index*perCount do
		local data = mailData[i]
		if data ~= nil then
			local mailInfo = GetMailInfoByData(data)
			table.insert(userMailInfo, mailInfo)
		end
	end--]]

	return 0, "获取邮件成功", userMailInfo, userNewsInfo
end

-- 查看邮件
function ReadMail(uid, id)
	local userMailData = GetUserMail(uid)

	local index 	= 0 -- 是否存在该邮件
	local mailData 	= {}
	for i,v in ipairs(userMailData.maildata) do
		if v.id == id then
			index = i
			mailData = v
			break
		end
	end

	-- 当前不存在该邮件 则返回当前最新邮件列表 当前最新邮件列表前端要求可通过删除邮件那条协议返回
	if index == 0 then
		-- local res = {}
		-- res["do"] = "Cmd.DeleteMailCmd_S"
		-- local _, _, userMailInfo = GetListUserMail(uid)
		-- res["data"] = {
		-- 	resultCode 	= 0, 
		-- 	desc 		= "用于邮件已失效时 同步当前最新邮件列表", 
		-- 	mailInfo 	= userMailInfo,
		-- }	
		-- local laccount = go.roomusermgr.GetRoomUserById(uid)
		-- unilight.success(laccount, res)	
		-- unilight.info("该邮件已失效 同步当前最新邮件列表")

		return 2, "该邮件已失效"
	end

	--[[ 只有第一次读取该邮件时 才检测是否有附件需要获取
	if mailData.state == ENUM_MAIL_STATE.UNREAD then
		--更新下状态
		if mailData.attachment ~= nil then
			userMailData.maildata[index].state = ENUM_MAIL_STATE.READ_HAS_ITEM
		else
			userMailData.maildata[index].state = ENUM_MAIL_STATE.READ_OVER
		end

		-- 存档
		SaveUserMail(userMailData)
	end]]

	-- 获取该邮件具体信息
	local mailInfo = GetMailInfoByData(mailData)
	if mailInfo.mailtype == 0 then
		userMailData.maildata[index].state = ENUM_MAIL_STATE.READ_OVER
		-- 存档
		SaveUserMail(userMailData)
	end
	--[[local isSend = false
	for i,v in ipairs(userMailData.maildata) do
		if v.state == ENUM_MAIL_STATE.UNREAD then
			isSend = true
			break
		end
	end
	if isSend == false then
        if CheckIsMatchLobby and CheckIsMatchLobby() then
            RedMsgPoint.UpdateRedPointMatch(uid, 1, 2)
		elseif RedMsgPoint and RedMsgPoint.AddRedPoint and type(RedMsgPoint.AddRedPoint) == "function" then
			local userData = unilight.getdata("userinfo", uid)
			RedMsgPoint.DelRedPoint(userData, RedMsgPoint.ENUM_REDPOINT.Task_NewMail)
		end
	end	]]

	if mailInfo.goto == 1 then   --跳转消息读完即删
		DeleteUserMail(uid, id)
	end
	return 0, "读取邮件成功", mailInfo
end

-- 删除邮件数据
function DeleteUserMail(uid, mailIds)
	local userMailData = GetUserMail(uid)

	if table.len(userMailData.maildata) == 0 then
		return 2, "邮件列表为空"
	end

	local remove = {}
	-- 遍历需要删除的所有邮件id
	for i,v in ipairs(mailIds) do
		remove[v] = true
	end
	local bOk = nil
	-- 遍历该玩家的邮件列表
	local maildata = {}
	for i,v in ipairs(userMailData.maildata) do
		-- 如果不在删除列表中 则 当前邮件保留
		if remove[v.id] ~= true then
			table.insert(maildata, v)
		elseif v.state ~= ENUM_MAIL_STATE.READ_OVER and v.attachment and table.empty(v.attachment) == false then
			table.insert(maildata, v)
			bOk = true
			--return 3, "存在附件奖励未领取"
		end
	end

	-- 确实删除了 某些邮件了 
	if table.len(maildata) < table.len(userMailData.maildata) then
		userMailData.maildata = maildata
		SaveUserMail(userMailData)

		-- local _, _, userMailInfo = GetListUserMail(uid)
		-- 存在未读邮件则 主动推送一下给前端 提示小红点
		local isSend = false
		for i,v in ipairs(userMailData.maildata) do
			if v.state == ENUM_MAIL_STATE.UNREAD then
				isSend = true
				break
			end
		end
		if isSend == false then
            if CheckIsMatchLobby and CheckIsMatchLobby() then
                RedMsgPoint.UpdateRedPointMatch(uid, 1, 2)
			elseif RedMsgPoint and RedMsgPoint.AddRedPoint and type(RedMsgPoint.AddRedPoint) == "function" then
				local userData = unilight.getdata("userinfo", uid)
				RedMsgPoint.DelRedPoint(userData, RedMsgPoint.ENUM_REDPOINT.Task_NewMail)
			end
		end	
		res["do"] = "Cmd.DeleteMailCmd_S"
		res["data"] = {
			resultCode 	= ret, 
			desc 		= desc,
			ids 		= cmd.data.ids
			}
			unilight.success(laccount, res)
		return 0, "删除邮件成功"
	else
		if bOk then
			return 4, "附件奖励未领取"
		end
		return 5, "邮件可能之前已被删除"
	end
end

function GetMailReward(uid, mailId)
	local userMailData = GetUserMail(uid)

	if table.len(userMailData.maildata) == 0 then
		return 2, "邮件列表为空"
	end

	local index 	= 0 -- 是否存在该邮件
	local mailData 	= {}
	for i,v in ipairs(userMailData.maildata) do
		if v.id == mailId then
			index = i
			mailData = v
			break
		end
	end

	-- 当前不存在该邮件
	if index == 0 then
		return 3, "该邮件已失效"
	end

	local receive = false
	if mailData.state ~= ENUM_MAIL_STATE.READ_OVER and mailData.attachment and table.empty(mailData.attachment) == false then
		for i,goods in ipairs(mailData.attachment) do  --加成
			--BackpackMgr.GetRewardGood(uid, goods.itemid, goods.itemnum, nil, nil, nil, ChessItemsHistory.ENUM_TYPE.MAIL, "邮件赠送")
		end
		receive = true
		userMailData.maildata[index].state = ENUM_MAIL_STATE.READ_OVER
		-- 存档
		SaveUserMail(userMailData)
	end
	if not receive then
		userMailData.maildata[index].state = ENUM_MAIL_STATE.READ_OVER
		-- 存档
		SaveUserMail(userMailData)
		return 3, "附件物品之前已经提取过"
	end
	local mailInfo = GetMailInfoByData(mailData)
	return 0, nil, mailInfo
end

-- 批量操作 opType: 1 全部处理 2 全部删除, ids：邮件id列表
function BulkOperationMail(uid, opType, ids)
	local userMailData = GetUserMail(uid)
	local attachment = {}
	if table.len(userMailData.maildata) == 0 then
		return 2, "没有可处理的邮件"
	end
	if opType == 1 then
		local op = false
		for i,mailData in ipairs(userMailData.maildata) do
			if mailData.state ~= ENUM_MAIL_STATE.READ_OVER then
				--ids为空则为全部领取
				if mailData.attachment and table.empty(mailData.attachment) == false and (table.empty(ids) or table.find(ids, mailData.id)) then
					for i,goods in ipairs(mailData.attachment) do
						BackpackMgr.GetRewardGood(uid, goods.itemid, goods.itemnum, nil, nil, nil, ChessItemsHistory.ENUM_TYPE.MAIL, "邮件赠送")
						attachment[goods.itemid] = (attachment[goods.itemid] or 0) + goods.itemnum
					end
					--处理过的才置为READ_OVER
					userMailData.maildata[i].state = ENUM_MAIL_STATE.READ_OVER
				end
				op = true
			end
		end
		if op == false then
			return 2, "没有可处理的邮件"
		end
	else
		local newMailData  = {}
		for i,mailData in ipairs(userMailData.maildata) do
			if mailData.state ~= ENUM_MAIL_STATE.READ_OVER and mailData.attachment and table.empty(mailData.attachment) == false then
				--return 3, "存在附件奖励未领取"
				table.insert(newMailData,mailData)
			end
		end
		userMailData.maildata = newMailData
	end

	-- 存档
	SaveUserMail(userMailData)

	-- 存在未读邮件则 主动推送一下给前端 提示小红点
	local isSend = false
	for i,v in ipairs(userMailData.maildata) do
		if v.state == ENUM_MAIL_STATE.UNREAD then
			isSend = true
			break
		end
	end
	if isSend == false then
        if CheckIsMatchLobby and CheckIsMatchLobby() then
            RedMsgPoint.UpdateRedPointMatch(uid, 1, 2)
		elseif RedMsgPoint and RedMsgPoint.AddRedPoint and type(RedMsgPoint.AddRedPoint) == "function" then
			local userData = unilight.getdata("userinfo", uid)
			RedMsgPoint.DelRedPoint(userData, RedMsgPoint.ENUM_REDPOINT.Task_NewMail)
		end
	end
	local resData = nil
	for k,v in pairs(attachment) do
		resData = resData or {}
    	local info = {
    		itemid = k,
    		itemnum = v
    	}
    	table.insert(resData, info)
	end
	return 0, nil, resData
end

-- 同意玩家申请发送邮件
function AgreeApplySendMail(userData, parentData, coin, applyType)
	if applyType == 0 then
		applyType = '充值'
	elseif applyType == 1 then
		applyType = '兑奖'
	end
	local mailInfo = {}
	mailInfo.charid = userData.uid
	mailInfo.subject = parentData.base.plataccount .. '已同意' .. applyType ..'申请'
	mailInfo.content = '您的'.. applyType ..'申请已成功,申请的币值为: ' .. coin .. '金币'
	mailInfo.type = 0
	ChessGmMailMgr.AddGlobalMail(mailInfo)
end

-- 同意玩家申请发送邮件
function RefuseApplySendMail(uid, parentData, coin, applyType, applyTime)
	if applyType == 0 then
		applyType = '充值'
	elseif applyType == 1 then
		applyType = '兑奖'
	end
	local mailInfo = {}
	mailInfo.charid = uid
	mailInfo.subject = parentData.base.plataccount .. '已拒绝' .. applyType ..'申请'
	mailInfo.content = '您的'.. applyType ..'申请已被拒绝,申请的币值为: ' .. coin .. ',申请时间:' .. applyTime
	mailInfo.type = 0
	ChessGmMailMgr.AddGlobalMail(mailInfo)
end
