require "script/gxlua/class"
require "script/gxlua/unilight"
require "script/do/common/staticconst"

CreateClass("UserTravel")   --单个玩家所有好友数据结构体

TravelShieldStatusEnum = {
    TravelShieldStatus_Close = 0,
    TravelShieldStatus_Open = 1,
}

function UserTravel:Init(uid)
    self.uid = uid
    --初始化旅行团等级
    self.level = 0

    --旅行团界面专用头像数据, 数字，来自配置表
    self.travelHead = 1 -- 1是配置表数据

    --旅行团备用头像，数字，来自配置表
    self.travelHeadBackUp = Map:New()
    self.travelHeadBackUp:Init()
    self.travelHeadBackUp:Insert(1,true)
    self.travelHeadBackUp:Insert(2,true)

    -- 旅行团功能 当前雇佣他的旅行团UID 如果为0表示空闲
    self.employUid = 0
    -- 当前雇佣他的旅行团名字
    self.employName = ""

    -- 雇佣CD时间时间到期前，需要知道上一次雇佣他的人是谁
    self.lastEmployUid = 0

    -- 旅行团功能 雇佣CD时间 cd时间到了，上一次雇佣他的对象可以重新雇佣他
    self.employCd = 0
    
    --旅行团成员映射，uid--加入旅行团时间
    self.members = Map:New()
    self.members:Init()

    --旅行团亲密度, 玩家UID--亲密值
    self.relationships = Map:New()
    self.relationships:Init()

    --今天剩余抓捕次数
    self.captureTimes = static_const.Static_Const_TRAVEL_INIT_MAX_CAPTURE_TIMES

    --上一次抓捕时间，用于隔天清理
    self.lastCaptureTime = 0

    --今天已经购买的抓捕次数，用于判断所学抓捕费用
    self.todayBuyCaptureTimes = 0

    --已经解锁的位置数目, 默认已经有3个
    self.unlockSlotCount = static_const.Static_Const_TRAVEL_Init_UNLOCK_SLOT_COUNT

    --防护罩数目
    self.shieldCount = static_const.Static_Const_TRAVEL_Init_Shield_Count
end

function UserTravel:SetDBTable(data)
    if data == nil then return end

    self.uid = data.uid or self.uid
    self.level = data.level or self.level
    self.travelHead = data.travelHead or self.travelHead

    if data.travelHeadBackUp ~= nil then
        for k,v in pairs(data.travelHeadBackUp) do
            self.travelHeadBackUp:Insert(k,v)
        end
    end

    self.employUid = data.employUid or self.employUid
    self.employName = data.employName or self.employName
    self.employCd = data.employCd or self.employCd
    self.lastEmployUid = data.lastEmployUid or self.lastEmployUid
    self.shieldCount = data.shieldCount or self.shieldCount
    self.todayBuyCaptureTimes = data.todayBuyCaptureTimes or self.todayBuyCaptureTimes
    
    if data.members ~= nil then
        for k,v in pairs(data.members) do
            self.members:Insert(k,v)
        end
    end

    if data.relationships ~= nil then
        for k,v in pairs(data.relationships) do
            self.relationships:Insert(k,v)
        end
    end

    self.captureTimes = data.captureTimes or self.captureTimes
    self.lastCaptureTime = data.lastCaptureTime or self.lastCaptureTime
    self.unlockSlotCount = data.unlockSlotCount or self.unlockSlotCount
end

function UserTravel:GetDBTable()
    local data = {}
    data.uid = self.uid
    data.level = self.level
    data.travelHead = self.travelHead
    data.travelHeadBackUp = { }
    self.travelHeadBackUp:ForEach(
        function(k,v)
            data.travelHeadBackUp[k] = v
        end
    )


    data.employUid = self.employUid
    data.employName = self.employName
    data.lastEmployUid = self.lastEmployUid
    data.employCd = self.employCd
    data.shieldCount = self.shieldCount

    data.members = {}
    self.members:ForEach(
        function(k,v)
            data.members[k] = v
        end
    )

    data.relationships = {}
    self.relationships:ForEach(
        function(k,v)
            data.relationships[k] = v
        end
    )

    data.captureTimes = self.captureTimes

    data.lastCaptureTime = self.lastCaptureTime

    data.todayBuyCaptureTimes = self.todayBuyCaptureTimes

    data.unlockSlotCount = self.unlockSlotCount

    return data
end

function UserTravel:GetTodayBuyCaptureTimes()
    return self.todayBuyCaptureTimes
end

function UserTravel:AddTodayBuyCaptureTimes()
    self.todayBuyCaptureTimes = self.todayBuyCaptureTimes + 1
end

function UserTravel:GetTodayBuyCaptureTimes_NeedCost() 
    if GlobalConst.Travel_Catch_COST[self.todayBuyCaptureTimes+1] ~= nil then
        return  GlobalConst.Travel_Catch_COST[self.todayBuyCaptureTimes+1]
    else
        return GlobalConst.Travel_Catch_COST[#GlobalConst.Travel_Catch_COST]
    end
end

function UserTravel:GetShieldCount()
    return self.shieldCount
end

function UserTravel:SubShieldCount()
    if self.shieldCount > 0 then
        self.shieldCount = self.shieldCount - 1
    end
end

function UserTravel:AddShieldCount(times)
    if times > 0 then
        self.shieldCount = self.shieldCount + times
    end
end

function UserTravel:GetTravelHead()
    return self.travelHead
end

function UserTravel:SetTravelHead(head)
    self.travelHead = head
end

function UserTravel:AddTravelHeadBackup(head)
    self.travelHeadBackUp:Insert(head, true)
end

function UserTravel:GetTravelHeadBackup()
    return self.travelHeadBackUp
end

function UserTravel:IsExistTravelHeadBackup(head)
    if self.travelHeadBackUp:Find(head) ~= nil then
        return true
    else
        return false
    end
end

function UserTravel:GetTravelHeadBackupCount()
    return self.travelHeadBackUp:Count()
end

function UserTravel:GetEmployEndLeftTime(uid)
    local tt = self:GetMemberTime(uid)
    if tt + static_const.Static_Const_TRAVEL_Employ_MAX_TIME > os.time then
        return tt + static_const.Static_Const_TRAVEL_Employ_MAX_TIME - os.time
    end
    return 0
end

function UserTravel:GetUnlockSlotCount()
    return self.unlockSlotCount
end

function UserTravel:AddUnlockSlotCount()
    self.unlockSlotCount = self.unlockSlotCount + 1
end

function UserTravel:GetCaptureTimes()
    return self.captureTimes
end

function UserTravel:DecCaptureTimes()
    if self.captureTimes > 0 then
        self.captureTimes = self.captureTimes - 1
    else
        self.captureTimes = 0
    end
end

function UserTravel:AddCaptureTimes(add)
    if add > 0 then
        self.captureTimes = self.captureTimes + add
    end
end

function UserTravel:GetLastCaptureTime()
    return self.lastCaptureTime
end

function UserTravel:SetLastCaptureTime()
    self.lastCaptureTime = os.time()
end

function UserTravel:ClearCaptureInfo()
    if common.IsSameDay(self.lastCaptureTime, os.time()) == false then
        self.lastCaptureTime = os.time()
        self.captureTimes = static_const.Static_Const_TRAVEL_INIT_MAX_CAPTURE_TIMES
    end
end


function UserTravel:PrintUserTravel()
    unilight.debug("-------打印旅行团程序信息-------------")
    local tmp = self:GetDBTable()
    unilight.debug(table2json(tmp))
end

--获取好友雇佣他的旅行团UID
function UserTravel:GetEmployUid()
    return self.employUid
end

function UserTravel:GetEmployName()
    return self.employName
end

function UserTravel:SetEmployName(name)
    self.employName = name
end

--设置好友雇佣他的旅行团UID
function UserTravel:SetEmployUid(uid)
    self.employUid = uid
end

-- 雇佣CD时间时间到期前，需要知道上一次雇佣他的人是谁
function UserTravel:GetLastEmployUid()
    return self.lastEmployUid
end

-- 雇佣CD时间时间到期前，需要知道上一次雇佣他的人是谁
function UserTravel:SetLastEmployUid(uid)
    self.lastEmployUid = uid
end

-- 旅行团功能 雇佣CD时间 cd时间到了，上一次雇佣他的对象可以重新雇佣他
function UserTravel:SetEmployCd()
    self.employCd = os.time() + static_const.Static_Const_TRAVEL_Employ_CD_Time
end

--- 是否处于雇佣CD时段里
function UserTravel:GetEmployCdLeftTime()
    if self.employCd > os.time() then
        return self.employCd - os.time()
    else
        return 0
    end
end

function UserTravel:ClearEmployCd()
    self.employCd = 0
end

function UserTravel:GetLevel()
    return self.level
end

function UserTravel:LevelUp()
    self.level = self.level + 1
end

function UserTravel:MembersForEach(fun, ...)
    self.members:ForEach(fun, ...)
end

function UserTravel:IsExistMembers(uid)
    if self.members:Find(uid) == nil then
        return false
    else
        return true
    end
end

function UserTravel:GetMemberTime(uid)
    local t = self.members:Find(uid)
    if t == nil then
        t = 0
    end
    return t
end

function UserTravel:AddMember(uid)
    self.members:Insert(uid, os.time())
end

--删除旅行团成员
function UserTravel:DelMember(uid)
    self.members:Remove(uid)
end

function UserTravel:GetMemberCount()
    return self.members:Count()
end

function UserTravel:GetRelationShip(uid)
    local t = self.relationships:Find(uid)
    if t == nil then
        t = 0
    end
    return t
end

function UserTravel:AddRelationShip(uid)
    local t = self.relationships:Find(uid)
    if t == nil then
        self.relationships:Insert(uid,1)
    else
        t = t + 1
        self.relationships:Replace(uid, t)
    end
end

--清理超时的旅行团成员
function UserTravel:ClearOutTimeMember()
    local out = {}
    self.members:ForEach(
        function(m_uid, m_time)
            if m_time + static_const.Static_Const_TRAVEL_Employ_MAX_TIME < os.time() then
                out[m_uid] = 0
            end
        end
    )

    local userInfo = UserInfo.GetUserInfoById(self.uid)

    for uid, v in pairs(out) do
        local friendData = FriendManager:GetFriendInfo(uid)
        if friendData ~= nil then
            local travelData = friendData:GetUserTravel()
            travelData:SetEmployUid(0)
            travelData:SetEmployName("")
            travelData:SetLastEmployUid(self.uid)
            travelData:SetEmployCd()
            travelData:AddRelationShip(self.uid)

            --雇佣完成，通知对方
            if userInfo ~= nil then
                message.give(uid, userInfo, MsgTypeEnum.TripGroupMeFinishEmploy)
            end

            local friend_userInfo = UserInfo.GetUserInfoById(uid)
            if friend_userInfo ~= nil then
                message.give(self.uid, friend_userInfo, MsgTypeEnum.TripGroupFriendFinishEmploy)
            end
        end
        self:DelMember(uid)
        self:AddRelationShip(uid)
    end

    return out
end

--定时查看数据
function UserTravel:CheckData(timer)
    self:ClearOutTimeMember()
end

function UserTravel.BuyShieldCountCallBack(uid, itemid, itemcount)
    unilight.debug("BuyShieldCountCallBack("..uid..","..itemid..","..itemcount)
    local req = {}
    req["do"] = "Cmd.NotifyUserBuyShieldCount_S"
    req["data"] = {
        shield_count = 0,
    }

    req.errno = unilight.SUCCESS
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    if laccount == nil then
        return
    end

    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    travelData:AddShieldCount(itemcount)
    req["data"].shield_count = travelData:GetShieldCount()

    unilight.success(laccount, req)
end

function UserTravel.AddTravelHeadBackupCallBack(uid, itemid, itemcount)
    unilight.debug("AddTravelHeadBackupCallBack("..uid..","..itemid..","..itemcount)
    local req = {}
    req["do"] = "Cmd.NotifyAddUserTravelHead_S"
    req["data"] = {
        head = 0,
    }

    req.errno = unilight.SUCCESS
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    if laccount == nil then
        return
    end

    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    local data = travelHead[itemid]
    if data ~= nil then
        travelData:AddTravelHeadBackup(data.head)
        req["data"].head = data.head
    else
        unilight.error("错误，无法通过itemid找到对应的头像,itemid:" .. itemid)
    end

    unilight.success(laccount, req)
end



