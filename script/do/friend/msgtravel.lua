

-- 客户端获得旅行团信息
Net.CmdGetUserTravelInfo_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetUserTravelInfo_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    res["data"] = {}
    res["data"].level = travelData:GetLevel()
    res["data"].head = travelData:GetTravelHead()
    res["data"].capture_times = travelData:GetCaptureTimes()
    res["data"].unlock_slot_count = travelData:GetUnlockSlotCount() - travelData:GetMemberCount()
    res["data"].today_buy_capture_times = travelData:GetTodayBuyCaptureTimes()
    res["data"].head_backup = {}

    local head_backup = travelData:GetTravelHeadBackup()
    head_backup:ForEach(
        function(k,v)
            table.insert(res["data"].head_backup, k)
        end
    )

    res["data"].member = {}

    --清理已经到期的旅行团成员
    travelData:ClearOutTimeMember()

    --轮询收集每个旅行团成员的数据
    travelData:MembersForEach(
        function(m_uid, m_time)
            if m_time + static_const.Static_Const_TRAVEL_Employ_MAX_TIME > os.time() then
                local member = { }
                member.uid = m_uid
                local member_friendData = FriendManager:GetFriendInfo(m_uid);  
                if member_friendData ~= nil then
                    local member_travelData = member_friendData:GetUserTravel()
                    member.head = member_travelData:GetTravelHead()
                    member.name = member_friendData:GetName()
                    member.star =  member_friendData:GetStar() 
                    member.sex =  member_friendData:GetSex() 
                    member.signature =  member_friendData:GetSignature()
                    member.area =  member_friendData:GetArea()
                    member.horoscope =  member_friendData:GetHoroscope()
                    member.relation_ship = travelData:GetRelationShip(m_uid)
                    member.travel_level = member_travelData:GetLevel()
                    member.level_time = (static_const.Static_Const_TRAVEL_Employ_MAX_TIME+m_time) - os.time()
                    table.insert(res["data"].member, member)
                end
            end
        end
    )

    travelData:PrintUserTravel()
    return res
end

-- 打开好友雇佣界面信息
Net.CmdGetTravelEmployFriend_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetTravelEmployFriend_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    res["data"] = {}
    res["data"].member = {}

    --清理已经到期的旅行团成员
    travelData:ClearOutTimeMember()

    --轮询好友信息， 筹集数据
    friendData:UserFriendsForEach(
        function(f_uid, f_info)
            if travelData:IsExistMembers(f_uid) == false then
                local f_friendData = FriendManager:GetFriendInfo(f_uid)
                if f_friendData ~= nil then
                    local f_travelData = f_friendData:GetUserTravel()
                    local tmp = {}
                    tmp.uid = f_uid
                    tmp.head = f_travelData:GetTravelHead()
                    tmp.name = f_friendData:GetName()
                    tmp.star =  f_friendData:GetStar()
                    tmp.sex =  f_friendData:GetSex()
                    tmp.signature =  f_friendData:GetSignature()
                    tmp.area =  f_friendData:GetArea()
                    tmp.horoscope =  f_friendData:GetHoroscope()
                    tmp.travel_level = f_travelData:GetLevel()
                    tmp.relation_ship = f_travelData:GetRelationShip(uid)
                    tmp.cur_employ_uid = f_travelData:GetEmployUid()
                    tmp.cur_employ_name = f_travelData:GetEmployName()
                    tmp.employ_cd = 0

                    --这说明你不久前雇佣过对方
                    if uid == f_travelData:GetLastEmployUid() then
                        tmp.employ_cd = f_travelData:GetEmployCdLeftTime()
                    else
                        tmp.employ_cd = 0
                    end
                    table.insert(res["data"].member, tmp)     
                end
            end
        end
    )

    return res
end

-- 打开推荐雇佣界面信息
Net.CmdGetTravelEmployRecommend_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetTravelEmployRecommend_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    res["data"] = {}
    res["data"].member = {}

    --清理已经到期的旅行团成员
    travelData:ClearOutTimeMember()

    --选择条件匹配的可推荐对象
    --玩家不能已经被雇佣
    --玩家不能是好友
    --玩家等级必须小
    --不能再CD时间里
    local count = 0
    for f_uid, f_friendData in pairs(FriendManager.userFriend.map) do
        if travelData:IsExistMembers(f_uid) == false and friendData:GetUserFriend(f_uid) == nil then
            local f_travelData = f_friendData:GetUserTravel()
            if travelData:GetLevel() >= f_travelData:GetLevel() and f_travelData:GetEmployUid() == 0 then
                --这说明你不久前雇佣过对方, 不在CD时间里
                if uid ~= f_travelData:GetLastEmployUid() or f_travelData:GetEmployCdLeftTime() == 0 then
                    local tmp = {}
                    tmp.uid = f_uid
                    tmp.head = f_travelData:GetTravelHead()
                    tmp.name = f_friendData:GetName()
                    tmp.star =  f_friendData:GetStar()
                    tmp.sex =  f_friendData:GetSex()
                    tmp.signature =  f_friendData:GetSignature()
                    tmp.area =  f_friendData:GetArea()
                    tmp.horoscope =  f_friendData:GetHoroscope()
                    tmp.travel_level = f_travelData:GetLevel()
                    tmp.relation_ship = f_travelData:GetRelationShip(uid)
                    tmp.cur_employ_uid = f_travelData:GetEmployUid()
                    tmp.cur_employ_name = f_travelData:GetEmployName()
                    tmp.employ_cd = 0

                    table.insert(res["data"].member, tmp)

                    if #res["data"].member >= static_const.Static_Const_TRAVEL_MAX_RECOMMEND_COUNT then
                        return res
                    end
                end
            end
        end
    end
    

    return res
end

-- 雇佣或抓捕玩家
Net.CmdEmployFriendToTravel_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.EmployFriendToTravel_S"

    if cmd["data"] == nil or type(cmd["data"].uid) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()
    local userInfo = UserInfo.GetUserInfoById(uid)

    if travelData:GetMemberCount() >= travelData:GetUnlockSlotCount() then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_NO_POS,
            desc = "没有更多位置了，需解锁新位置"
        }
        return res
    end

    local employ_uid = cmd["data"].uid

    local employ_friendData = FriendManager:GetFriendInfo(employ_uid)
    if employ_friendData == nil then
        res["data"] = {
            resultCode = 1,
            desc = "对方不存在"
        }
        return res
    end

    local employ_travelData = employ_friendData:GetUserTravel()

    if travelData:IsExistMembers(employ_uid) == true then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_CANNOT_EMPLY_TWICE,
            desc = "已经被你雇佣过了"
        }
        return res
    end

    if employ_travelData:GetLastEmployUid() == uid then
        if employ_travelData:GetEmployCdLeftTime() > 0 then
            res["data"] = {
                resultCode = ERROR_CODE.TRAVEL_IN_EMPLOY_CD,
                desc = "雇佣CD时间，暂时不能被你雇佣"
            }
            return res
        end
    end

    if employ_travelData:GetLevel() > travelData:GetLevel() then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_LEVEL_LIMIT,
            desc = "该好友等级高过你，不能雇佣（抓捕）"
        }
        return res
    end

    local isCapture = false
    --玩家正在别雇佣，抓捕他们 删除原有的雇佣信息，并通知对方
    if employ_travelData:GetEmployUid() ~= 0 then

        --抓捕逻辑,抓捕次数有限制
        if friendData:GetUserFriend(employ_uid) == nil then
            res["data"] = {
                resultCode = 1,
                desc = "不是你的好友，不能抓捕"
            }
            return res
        end

        --清理一下抓捕次数
        travelData:ClearCaptureInfo()

        --查看玩家当前抓捕次数
        if travelData:GetCaptureTimes() <= 0 then      
            --扣钱和比较钱的操作
            if UserInfo.CheckUserMoneyByUid(uid, static_const.Static_MoneyType_Diamond, travelData:GetTodayBuyCaptureTimes_NeedCost()) == false then
                res["data"] = {
                    resultCode = ERROR_CODE.DIAMOND_NOT_ENOUGH,
                    desc = "你的砖石不够"
                }
                return res
            end

            UserInfo.SubUserMoneyByUid(uid, static_const.Static_MoneyType_Diamond, travelData:GetTodayBuyCaptureTimes_NeedCost())
            travelData:AddTodayBuyCaptureTimes()
        end

        --减少一次抓捕次数
        travelData:DecCaptureTimes()

        --任务系统，任务完成情况
        if userInfo ~= nil then
            userInfo.achieveTask:addProgress(TaskConditionEnum.CaptureFriendEvent, 1)
            userInfo.dailyTask:addProgress(TaskConditionEnum.CaptureFriendEvent, 1)
        end

       local last_uid = employ_travelData:GetEmployUid()
       local last_friendData = FriendManager:GetFriendInfo(last_uid)
       if last_friendData ~= nil then
            local last_travelData = last_friendData:GetUserTravel()

            if last_travelData:GetShieldCount() > 0 then
                last_travelData:SubShieldCount()

                --抓捕了对方好友，但失败了
                if userInfo ~= nil then
                    message.give(last_uid, userInfo, MsgTypeEnum.FriendRobbedWithFailure)
                end

                --任务系统，任务完成情况
                local last_userInfo = UserInfo.GetUserInfoById(last_uid)
                if last_userInfo ~= nil then
                    last_userInfo.achieveTask:addProgress(TaskConditionEnum.StopCaptureEvent, 1)
                    last_userInfo.dailyTask:addProgress(TaskConditionEnum.StopCaptureEvent, 1)
                end

                res["data"] = {
                    resultCode = 0,
                    desc = "",
                    capture_times = travelData:GetCaptureTimes(),
                    today_buy_capture_times = travelData:GetTodayBuyCaptureTimes(),
                    type = 1,
                }
                return res
            end

            last_travelData:DelMember(employ_uid)
            isCapture = true

            --抓捕了对方好友，通知下对方
            if userInfo ~= nil then
                message.give(last_uid, userInfo, MsgTypeEnum.FriendRobbed)
            end

            if last_friendData:GetOnline() == true then
                --在线的话通知对方
                local req = { }
                req["do"] = "Cmd.NotifyUserTravelCapture_S"
                req["data"] = { 
                    uid = employ_uid,
                }
                req.errno = unilight.SUCCESS
                local last_laccount = go.roomusermgr.GetRoomUserById(last_uid)
                if last_laccount == nil then
                    unilight.debug("sorry, the laccount of the ask_uid:" .. last_laccount .. " is nil")
                else
                    unilight.success(last_laccount, req)
                end
            end
       end
    end

    --设置抓捕信息
    employ_travelData:SetEmployUid(uid)
    employ_travelData:SetEmployName(friendData:GetName())
    travelData:AddMember(employ_uid)

    --任务系统，任务完成情况
    if isCapture == false then
        if userInfo ~= nil then
            userInfo.achieveTask:addProgress(TaskConditionEnum.EmployFriendEvent, 1)
            userInfo.dailyTask:addProgress(TaskConditionEnum.EmployFriendEvent, 1)
        end
    end

    res["data"] = {
        resultCode = 0,
        desc = "雇佣成功",
        capture_times = travelData:GetCaptureTimes(),
        today_buy_capture_times = travelData:GetTodayBuyCaptureTimes(),
        member = {
            uid = employ_uid,
            head = employ_travelData:GetTravelHead(),
            name = employ_friendData:GetName(),
            star =  employ_friendData:GetStar(),
            sex =  employ_friendData:GetSex(),
            signature =  employ_friendData:GetSignature(),
            area =  employ_friendData:GetArea(),
            horoscope =  employ_friendData:GetHoroscope(),
            travel_level = employ_travelData:GetLevel(),
            relation_ship = employ_travelData:GetRelationShip(uid),
            travel_level = employ_travelData:GetLevel(),
            level_time = static_const.Static_Const_TRAVEL_Employ_MAX_TIME,
        },
        type = 0,
    }

    local employ_userInfo = UserInfo.GetUserInfoById(uid)
    if employ_userInfo ~= nil and isCapture == true then
        res["data"].world = employ_userInfo.world:sn()
    end
    return res
end

-- 清楚雇佣CD时间
Net.CmdClearEmployFriendCD_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.ClearEmployFriendCD_S"

    if cmd["data"] == nil or type(cmd["data"].uid) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()
    
    local employ_uid = cmd["data"].uid

    --判断对方是否存在
    local employ_friendData = FriendManager:GetFriendInfo(employ_uid)
    if employ_friendData == nil then
        res["data"] = {
            resultCode = 1,
            desc = "对方不存在"
        }
        return res
    end

    local employ_travelData = employ_friendData:GetUserTravel()

    --判断是否已经被你雇佣
    if travelData:IsExistMembers(employ_uid) == true then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_CANNOT_EMPLY_TWICE,
            desc = "已经被你雇佣过了"
        }
        return res
    end

    --判断当前等级
    if employ_travelData:GetLevel() > travelData:GetLevel() then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_LEVEL_LIMIT,
            desc = "该好友等级高过你，不能雇佣（抓捕）"
        }
        return res
    end

    --如果需要清理的话
    if employ_travelData:GetLastEmployUid() == uid then
        if employ_travelData:GetEmployCdLeftTime() > 0 then
            --扣钱和比较钱的操作
            if UserInfo.CheckUserMoneyByUid(uid, static_const.Static_MoneyType_Diamond, GlobalConst.Travel_CD_Diamond) == false then
                res["data"] = {
                    resultCode = ERROR_CODE.DIAMOND_NOT_ENOUGH,
                    desc = "你的砖石不够"
                }
                return res
            end

            UserInfo.SubUserMoneyByUid(uid, static_const.Static_MoneyType_Diamond, GlobalConst.Travel_CD_Diamond)
            --
            employ_travelData:SetLastEmployUid(0)
            employ_travelData:ClearEmployCd()
        end
    end

    res["data"] = {
        resultCode = 0,
        desc = "清理成功",
        uid = employ_uid,
    }
    return res
end

-- 购买抓捕次数
Net.CmdBuyCaptureFriendTime_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.BuyCaptureFriendTime_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    --比较钱的操作


    --增加抓捕次数
    travelData:AddCaptureTimes(1)
    res["data"] = {
        resultCode = 0,
        desc = "购买成功"
    }
    return res
end

-- 解除雇佣关系
Net.CmdRescissionEmployFriendShip_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.RescissionEmployFriendShip_S"

    if cmd["data"] == nil or type(cmd["data"].uid) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    local employ_uid = cmd["data"].uid

    --判断对方是否存在
    local employ_friendData = FriendManager:GetFriendInfo(employ_uid)
    if employ_friendData == nil then
        res["data"] = {
            resultCode = 1,
            desc = "对方不存在"
        }
        return res
    end

    local employ_travelData = employ_friendData:GetUserTravel()

    --判断是否已经被你雇佣
    if travelData:IsExistMembers(employ_uid) == true then
        travelData:DelMember(employ_uid)
        employ_travelData:SetEmployUid(0)
        employ_travelData:SetEmployName("")
    end   
    
    res["data"] = {
        resultCode = 0,
        desc = "",
        uid = employ_uid,
    }

    return res
end

-- 团长升级
Net.CmdUserTravelLevelUp_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.UserTravelLevelUp_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()
    local level = travelData:GetLevel()

    --升级自身需要的条件traveLevel
    local need = traveLevel.query(level)
    if need ~= nil then
        if friendData:GetStar() < need.star then
            res["data"] = {
                resultCode = ERROR_CODE.TRAVEL_STAR_NOT_ENOUGH,
                desc = "星级不够"
            }
            return res
        end

        local money_table = string.split(need.cost, "_")
        local money_type, money =  money_table[1], money_table[2]
        if money_type == nil or money == nil then
            unilight.error("配置表数据出错.........")
            res["data"] = {
                resultCode = 1,
                desc = "",
            }
            return res 
        end
        if UserInfo.CheckUserMoneyByUid(uid, money_type, money) ~= true then
            res["data"] = {
                resultCode = ERROR_CODE.MONEY_NOT_ENOUGH,
                desc = "抱歉，你的钱不够"
            }
            return res
        end

        UserInfo.SubUserMoneyByUid(uid, money_type, money)
    end

    travelData:LevelUp()

    res["data"] = {
        resultCode = 0,
        desc = "升级成功",
        unlock_count = 0,
    }

    --团员位置解锁的条件
    local cond = travelUnlock.query(travelData:GetUnlockSlotCount()+1)
    if cond ~= nil then
        if travelData:GetLevel() >= cond.level then
            travelData:AddUnlockSlotCount()
            res["data"].unlock_count = 1
        end
    end

    --任务系统，任务完成情况
    local userInfo = UserInfo.GetUserInfoById(uid)
    if userInfo ~= nil then
        userInfo.achieveTask:addProgress(TaskConditionEnum.TravelLevelupEvent, 1)
    end

    return res
end

-- 团员位置解锁
Net.CmdUserTravelUnlockSlot_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.UserTravelUnlockSlot_S"

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    if travelData:GetUnlockSlotCount() >= static_const.Static_Const_TRAVEL_MAX_EMPLOY_USER_COUNT then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_POS_LIMIT,
            desc = "已经达到最大值，解锁失败"
        }
        return res
    end

    --团员位置解锁的条件
    local cond = travelUnlock.query(travelData:GetUnlockSlotCount()+1)
    if cond ~= nil then
        if travelData:GetLevel() < cond.level then
            res["data"] = {
                resultCode = ERROR_CODE.TRAVEL_LEVEL_NOT_ENOUGH,
                desc = "抱歉，团长等级不够，不能解锁"
            }
            return res
        end
    end

    travelData:AddUnlockSlotCount()
    res["data"] = {
        resultCode = 0,
        desc = "位置解锁成功"
    }
    return res
end

--更改玩家的旅行团头像
Net.CmdChangeUserTravelHead_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.ChangeUserTravelHead_S"

    --检查客户端输入数据
    if cmd["data"] == nil or cmd["data"].head == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据错误",
        }
        return res       
    end

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()
    local head = cmd["data"].head

    if head == travelData:GetTravelHead() then
        res["data"] = {
            resultCode = 0,
            desc = "",
        }
        return res     
    end

    if travelData:IsExistTravelHeadBackup(head) == false then
        res["data"] = {
            resultCode = ERROR_CODE.TRAVEL_NEED_BUY_HEAD,
            desc = "这个头像需要先购买",
        }
        return res 
    end

    travelData:SetTravelHead(head)

    res["data"] = {
        resultCode = 0,
        desc = "",
        head = head,
    }
    return res
end