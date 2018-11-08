require "script/do/common/staticconst"
require "script/do/UserInfo"

-- 邀请游戏，发送邀请你玩着游戏的玩家UID
Net.CmdBeAskedPlayGame_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.BeAskedPlayGame_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    
    --检查客户端数据输入
    if cmd["data"] == nil or cmd["data"].uid == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res;
    end

    local ask_uid = cmd["data"].uid
    if ask_uid == uid then
        res["data"] = {
            resultCode = 1,
            desc = "不能邀请自己"
        }
        return res
    end

    local askFriendData = FriendManager:GetFriendInfo(ask_uid);

    if askFriendData == nil then
        res["data"] = {
            resultCode = 1,
            desc = "错误，对方不存在"
        }
        return res
    end

    --unilight.debug("玩家(" .. askFriendData:GetName() .. ") 成功邀请了 玩家(" .. friendData:GetName() .. ") 玩游戏")

    friendData:SetAskMePlayGameUid(ask_uid)
    askFriendData:AddMeAskPlayerUids(uid)

    if friendData:GetUserFriend(uid) == nil then
        friendData:AddUserFriend(askFriendData:GetUid(), askFriendData:GetHead(), askFriendData:GetName(), askFriendData:GetAppId(), true)
        askFriendData:AddUserFriend(friendData:GetUid(), friendData:GetHead(), friendData:GetName(), friendData:GetAppId(), true)
    end

    local userInfo = UserInfo.GetUserInfoById(uid)
    unilight.debug("CmdBeAskedPlayGame_C, uid="..uid..", firstLogin="..userInfo["firstLogin"])
    if userInfo["firstLogin"] == 1 then
        askFriendData:AddMeAskPlayerUidsAndFirstLogin(uid)
    end

    ---可能的发放奖励代码，以后加上


    
    --任务系统，任务完成情况
    local ask_userInfo = UserInfo.GetUserInfoById(ask_uid)
    if ask_userInfo ~= nil then
        ask_userInfo.achieveTask:addProgress(TaskConditionEnum.AskFriendEvent, 1)
        ask_userInfo.dailyTask:addProgress(TaskConditionEnum.AskFriendEvent, 1)
    end

    return res
end

-- 客户端建号时发送QQ好友消息
Net.CmdSendUserQQFriendDataCmd_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.SendUserQQFriendDataCmd_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local data = cmd["data"]

    --检查客户端数据输入
    if data == nil or data.self_data == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res;
    end

    if type(data.self_data.head) ~= "string" or type(data.self_data.name) ~= "string" 
    or type(data.self_data.app_id) ~= "string" or type(data.self_data.sex) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res;
    end

    --先将自己的QQ数据保存下来
    friendData:SetBaseInfo(uid, data.self_data.head, data.self_data.name, data.self_data.app_id, data.self_data.sex)
	UserInfo.UpdateQqData(uid, data.self_data.head, data.self_data.name, data.self_data.sex)

    FriendManager:SaveUserQQInfo(data.self_data.app_id, uid)

    --FriendManager:PrintUserQQInfo()

    --获取QQ好友信息，并且查看QQ好友是否有在玩本游戏，有的话，添加为好友
    for i, v in ipairs(data.friend_data) do
        --检查客户端数据输入
        if type(v.head) ~= "string" or type(v.name) ~= "string" or type(v.app_id) ~= "string" then
            res["data"] = {
                resultCode = 1,
                desc = "数据出错"
            }
            return res;
        end

        --判断是否双方是QQ好友，如果是就相互添加为好友
        local qqData_uid = FriendManager:GetUserQQInfo(v.app_id)

        if qqData_uid ~= nil and friendData:GetUserFriend(qqData_uid) == nil then
            local qq_friend_data = FriendManager:GetFriendInfo(qqData_uid)
            if qq_friend_data ~= nil and friendData:IsExistDeleteQQFriend(qqData_uid) == false then
                friendData:AddUserFriend(qq_friend_data:GetUid(), qq_friend_data:GetHead(), qq_friend_data:GetName(), qq_friend_data:GetAppId(), true)
                qq_friend_data:AddUserFriend(friendData:GetUid(), friendData:GetHead(), friendData:GetName(), friendData:GetAppId(), true)
            end
        end
    end

    res["data"] = {
        resultCode = 0,
    }
    return res;
end

-- 获取玩家游戏好友信息
Net.CmdGetUserFriendDataCmd_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetUserFriendDataCmd_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    res["data"] = {
        self_data = {
            uid = uid,
            name = friendData:GetName(),
            head = friendData:GetHead(),
            sex = friendData:GetSex(),
            star = friendData:GetStar(),
            signature =  friendData:GetSignature(), 
            area =  friendData:GetArea(), 
            horoscope =  friendData:GetHoroscope(),
            friend_ship = 0,
            money = friendData:GetMoney(),
            product = friendData:GetProduct(),
            click = friendData:GetClick(),
        },

        friend_data = {},
    }

    --获取QQ好友数据
    friendData:UserFriendsForEach(
        function(k,v)
            local f_friendData = FriendManager:GetFriendInfo(k)
            if f_friendData ~= nil then
                local data = {
                    uid = k,
                    name = f_friendData:GetName(), 
                    head =  f_friendData:GetHead(), 
                    star =  f_friendData:GetStar(), 
                    sex =  f_friendData:GetSex(), 
                    signature =  f_friendData:GetSignature(), 
                    area =  f_friendData:GetArea(), 
                    horoscope =  f_friendData:GetHoroscope(),
                    friend_ship = travelData:GetRelationShip(k),
                    money = f_friendData:GetMoney(),
                    product = f_friendData:GetProduct(),
                    click = f_friendData:GetClick()
                }
                table.insert(res["data"].friend_data, data)               
            end       
        end
    )

    return res
end

--获得玩家被邀请为好友的列表
Net.CmdGetUserAskedAddFriends_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetUserAskedAddFriends_S"
    res["data"] = { }
    res["data"].friend_data = { }

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    --玩家不在线时， 被邀请为好友处理
    friendData:AskAddFriendsForEach(
        function(k,v)
            local ask_uid = k
            local ask_friend_data = FriendManager:GetFriendInfo(ask_uid)
            if ask_friend_data ~= nil then
                local req = { 
                    uid = ask_uid,
                    name = ask_friend_data:GetName(), 
                    head =  ask_friend_data:GetHead(), 
                    star =  ask_friend_data:GetStar(), 
                    sex =  ask_friend_data:GetSex(), 
                    signature =  ask_friend_data:GetSignature(), 
                    area =  ask_friend_data:GetArea(), 
                    horoscope =  ask_friend_data:GetHoroscope(),
                    friend_ship = travelData:GetRelationShip(ask_uid),
                }
                table.insert( res["data"].friend_data, req)
            end
        end
    )
    return res
    --friendData:ClearAskAddFriends()
end

-- 发送好友请求
Net.CmdSendReqAddFriendCmd_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.SendReqAddFriendCmd_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    --检查客户端输入
    if cmd["data"] == nil or type(cmd["data"].friend_uid) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end


    --好友上线，如果已经达到上线的话
    if friendData:GetFriendsCount() >= static_const.Static_Const_Friend_MAX_Friend_Count then
        res["data"] = {
            resultCode = ERROR_CODE.FRIENDS_MAX_LIMIT,
            desc = "好友数量已达上限"
        }
        return res
    end

    --如果已经是好友的话
    local ask_uid = cmd["data"].friend_uid;
    if friendData:GetUserFriend(ask_uid) ~= nil then
        res["data"] = {
            resultCode = ERROR_CODE.FRIENDS_IS_YOUR_FRIEND,
            desc = "对方已是你的好友"
        }
        return res
    end

    if ask_uid == uid  then
        res["data"] = {
            resultCode = ERROR_CODE.FRIENDS_CAN_ADD_SELF,
            desc = "不能加自己为好友"
        }
        return res
    end

    --检查自己今天的邀请信息
    if friendData:IsExistTodayAskedFriends(ask_uid) == true then
        res["data"] = {
           resultCode = ERROR_CODE.FRIENDS_APPLY_TOO_MUCH,
           desc = "已经申请"
        }
       return res       
    end

    --如果对方不在线， 查询保留的申请信息，如果有你，说明你多次申请了
    local askFriendData = FriendManager:GetFriendInfo(ask_uid);

    if askFriendData == nil then
        res["data"] = {
            resultCode = 1,
            desc = "错误，对方不存在"
        }
        return res
    end

    unilight.debug("name:" .. friendData:GetName() .. " 向name:" .. askFriendData:GetName() .. " 发送好友请求")

    --记录今天邀请过的好友
    friendData:AddTodayAskedFriends(ask_uid)
    askFriendData:AddAskAddFriends(uid)

	--给被邀请的人，一条消息记录
	local userInfo = UserInfo.GetUserInfoById(uid)
    message.give(ask_uid, userInfo, MsgTypeEnum.FriendApply)
    
    --任务系统，任务完成情况
    local userInfo = UserInfo.GetUserInfoById(uid)
    if userInfo ~= nil then
        userInfo.achieveTask:addProgress(TaskConditionEnum.ApplyFriendEvent, 1)
        userInfo.dailyTask:addProgress(TaskConditionEnum.ApplyFriendEvent, 1)
    end

    --需要知道对方是否在线,如果不在线的话，先把请求存起来
    if askFriendData:GetOnline() == false then
        return res
    else
        --在线的话发送好友请求给对方
        local req = { }
        req["do"] = "Cmd.SendReqBeAddFriendCmd_S"
        req["data"] = { 
            uid = uid,
            name = friendData:GetName(), 
            head =  friendData:GetHead(), 
            star =  friendData:GetStar(), 
            sex =  friendData:GetSex(), 
            signature =  friendData:GetSignature(), 
            area =  friendData:GetArea(), 
            horoscope =  friendData:GetHoroscope(),
            friend_ship = travelData:GetRelationShip(ask_uid),
        }
        req.errno = unilight.SUCCESS
        local ask_laccount = go.roomusermgr.GetRoomUserById(ask_uid)
        if ask_laccount == nil then
            unilight.debug("sorry, the laccount of the ask_uid:" .. ask_uid .. " is nil")
        else
            unilight.success(ask_laccount, req)
        end
        
        return res
    end
end

-- 同意或拒绝好友请求
Net.CmdSendReqAgreeAddFriendCmd_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.SendReqAgreeAddFriendCmd_S"

    --客户端数据参数检查
    if cmd["data"] == nil or type(cmd["data"].agree) ~= "boolean" or type(cmd["data"].uid) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end
    local agree = cmd["data"].agree
    local ask_uid = cmd["data"].uid

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);

    if uid == ask_uid then
        res["data"] = {
            resultCode = 1,
            desc = "不能添加自己为好友"
        }
        return res
    end

    friendData:DelAskAddFriends(ask_uid)
    local ask_friendData = FriendManager:GetFriendInfo(ask_uid);
    if ask_friendData == nil then
        res["data"] = {
            resultCode = 1,
            desc = "对方不存在"
        }
        return res
    end

    --删除今天申请记录
    ask_friendData:DelTodayAskedFriends(uid)

    --如果同意的话，就相互加为好友
    if agree == true then
        --删除QQ好像删除信息
        local isQQFriend = false
        if friendData:IsExistDeleteQQFriend(ask_uid) == true then
            isQQFriend = true
        end
        friendData:DelDeleteQQFriend(ask_uid)
        ask_friendData:DelDeleteQQFriend(uid)

        if friendData:GetFriendsCount() >= static_const.Static_Const_Friend_MAX_Friend_Count then
            res["data"] = {
                resultCode = ERROR_CODE.FRIENDS_MAX_LIMIT,
                desc = "好友数目已经达到上限，不能添加"
            }
            return res
        end

        if ask_friendData:GetFriendsCount() >= static_const.Static_Const_Friend_MAX_Friend_Count then
            res["data"] = {
                resultCode = ERROR_CODE.FRIENDS_MAX_LIMIT,
                desc = "对方好友数目已经达到上限，不能添加"
            }
            return res
        end

        unilight.debug("name:" .. friendData:GetName() .. "同意加name:" .. ask_friendData:GetName() .. " 为好友")
        friendData:AddUserFriend(ask_friendData:GetUid(), ask_friendData:GetHead(), ask_friendData:GetName(), ask_friendData:GetAppId(), isQQFriend)
        ask_friendData:AddUserFriend(friendData:GetUid(), friendData:GetHead(), friendData:GetName(), friendData:GetAppId(), isQQFriend)

        if ask_friendData:GetOnline() == true then
            res["data"] = {
                resultCode = 0,
                desc = "添加好友成功"
            }

            local req = {}
            req["do"] = "Cmd.SendReqAgreeAddFriendCmd_S"
            req["data"] = { 
                resultCode = 0,
                desc = "添加好友成功"
            }
            req.errno = unilight.SUCCESS
            local ask_laccount = go.roomusermgr.GetRoomUserById(ask_uid)
            if ask_laccount == nil then
                unilight.debug("sorry, the laccount of the ask_uid:" .. ask_uid .. " is nil")
            else
                unilight.success(ask_laccount, req)
            end
        end
    end

    return res
end

-- 删除好友
Net.CmdSendReqDeleteFriendCmd_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.SendReqDeleteFriendCmd_S"

    if cmd["data"] == nil or type(cmd["data"].uid) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res;
    end

    local del_uid = cmd["data"].uid

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid)
    local delFriendData = FriendManager:GetFriendInfo(del_uid)

    --如果是QQ好友的话，记录一下，免得下次登入又被加上
    if friendData:GetUserFriend(del_uid) ~= nil then
        local tmp = friendData:GetUserFriend(del_uid)
        if tmp:GetIsQQFriend() == true then
            unilight.debug("是QQ好友，删除QQ好友，记录一下")
            friendData:AddDeleteQQFriend(del_uid)
        end
        friendData:DelUserFriend(del_uid)
    end

    --如果是QQ好友的话，记录一下，免得下次登入又被加上
    if delFriendData:GetUserFriend(uid) ~= nil then
        local tmp = delFriendData:GetUserFriend(uid)
        if tmp:GetIsQQFriend() == true then
            unilight.debug("是QQ好友，删除QQ好友，记录一下")
            delFriendData:AddDeleteQQFriend(uid)
        end
        delFriendData:DelUserFriend(uid)
    end

    --删除今天邀请和推荐
    friendData:DelTodayAskedFriends(del_uid)
    delFriendData:DelTodayAskedFriends(uid)
    friendData:DelRecommendFriends(del_uid)
    delFriendData:DelRecommendFriends(uid)

    res["data"] = {
        resultCode = 0,
        desc = "删除好友成功"
    }
    return res
end

--推荐好友
Net.CmdSendReqRecommendFriendCmd_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.SendReqRecommendFriendCmd_S"
    res["data"] = {}
    res["data"].friends = {}

    local uid = laccount.Id 
    local friendData = FriendManager:GetOrNewFriendInfo(uid)
    local travelData = friendData:GetUserTravel()

    unilight.debug("------向玩家(" .. friendData:GetName() .. ")推荐好友------------")

    --收集被推荐的好友
    local tmp = {}

    for k, v in pairs(friendData.deleteQQFriend) do
         --推荐好友，满足条件 1不是自己 2不是好友 3今天没有被推荐过 4今天没有被邀请过
         if k ~= uid and friendData:GetUserFriend(k) == nil and 
            friendData:IsRecommendedToFriend(k) == false and 
            friendData:IsExistTodayAskedFriends(uid) == false then
            local friendInfo = FriendManager:GetFriendInfo(k)
            if friendInfo ~= nil then
                local info = {
                    uid = k,
                    name = friendInfo:GetName(), 
                    head =  friendInfo:GetHead(), 
                    star =  friendInfo:GetStar(), 
                    sex =  friendInfo:GetSex(), 
                    signature =  friendInfo:GetSignature(), 
                    area =  friendInfo:GetArea(), 
                    horoscope =  friendInfo:GetHoroscope(),
                    friend_ship = travelData:GetRelationShip(k),
                }
                table.insert(res["data"].friends, info)

                --如果人数多于20直接发送，如果没有从以前推荐过的列表中插入
                if #res["data"].friends >= 20 then
                    return res 
                end
            end
         end
    end

    for i = 0, 100, 1 do
        local friendInfo = FriendManager:GetRandomFriendInfo()
        --推荐好友，满足条件 1不是自己 2不是好友 3今天没有被推荐过 4今天没有被邀请过
        if friendInfo ~= nil and friendInfo:GetUid() ~= uid and friendData:GetUserFriend(friendInfo:GetUid()) == nil and 
        friendData:IsRecommendedToFriend(friendInfo:GetUid()) == false and 
        friendData:IsExistTodayAskedFriends(uid) == false and
        friendInfo:GetName() ~= "" and friendInfo:GetHead() ~= "" then
            local info = {
                uid = friendInfo:GetUid(),
                name = friendInfo:GetName(), 
                head =  friendInfo:GetHead(), 
                star =  friendInfo:GetStar(), 
                sex =  friendInfo:GetSex(), 
                signature =  friendInfo:GetSignature(), 
                area =  friendInfo:GetArea(), 
                horoscope =  friendInfo:GetHoroscope(),
                friend_ship = travelData:GetRelationShip(friendInfo:GetUid()),
            }
            table.insert(res["data"].friends, info)
            tmp[friendInfo:GetUid()] = true
        end

        --如果人数多于20直接发送，如果没有从以前推荐过的列表中插入
        if #res["data"].friends >= 20 then
            for tmpk,tmpv in pairs(tmp) do
                --记录已经被推荐
                friendData:AddRecommendFriends(tmpk)
                
            end
            return res 
        end

    end
    

    --如果人数多于20直接发送，如果没有从以前推荐过的列表中插入
    for k,v in pairs(friendData.recommendFriends.map) do
        if k ~= uid and friendData:GetUserFriend(k) == nil and 
        friendData:IsExistTodayAskedFriends(k) == false then
            local friendInfo = FriendManager:GetFriendInfo(k)
            if friendInfo ~= nil and friendInfo:GetName() ~= "" and friendInfo:GetHead() ~= "" then
                local info = {
                    uid = k,
                    name = friendInfo:GetName(), 
                    head =  friendInfo:GetHead(), 
                    star =  friendInfo:GetStar(), 
                    sex =  friendInfo:GetSex(), 
                    signature =  friendInfo:GetSignature(), 
                    area =  friendInfo:GetArea(), 
                    horoscope =  friendInfo:GetHoroscope(),
                    friend_ship = travelData:GetRelationShip(k),
                }
                table.insert(res["data"].friends, info)
                --如果人数多于20直接发送
                if #res["data"] >= 20 then
                    for tmpk,tmpv in pairs(tmp) do
                        --记录已经被推荐
                        friendData:AddRecommendFriends(tmpk)
                        
                    end
                    return res 
                end
            end
        end
    end
    

    for tmpk,tmpv in pairs(tmp) do
        --记录已经被推荐
        friendData:AddRecommendFriends(tmpk)
    end

    return res
end

--通过UID获得对方信息
Net.CmdGetUserInfoByUid_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetUserInfoByUid_S"

    local uid = cmd["data"].uid
    local friendData = FriendManager:GetFriendInfo(uid)

    if friendData ~= nil then
        local travelData = friendData:GetUserTravel()
        res["data"] = {
            resultCode = 0,
            desc = "",
            uid = uid,
            name = friendData:GetName(), 
            head =  friendData:GetHead(), 
            star =  friendData:GetStar(), 
            sex =  friendData:GetSex(), 
            signature =  friendData:GetSignature(), 
            area =  friendData:GetArea(), 
            horoscope =  friendData:GetHoroscope(),
            friend_ship = travelData:GetRelationShip(uid),
        }
    else
        res["data"] = {
            resultCode = 1,
            desc = "玩家不存在",
        }
    end
    return res
end
