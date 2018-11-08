require "script/gxlua/class"
require "script/gxlua/unilight"
require "script/do/common/Common"

CreateClass("UserFriend")   --单个玩家所有好友数据结构体
CreateClass("UserFriendSimpleData")

function UserFriendSimpleData:Init()
    self.name = ""  --玩家名字 nickname
    self.signature = "" --玩家签名
    self.area = "" --玩家所在地区
    self.horoscope = "" --未设计
    self.head = ""  --玩家在游戏中的头像
    self.star = 1  --玩家星际
    self.sex = 1 --玩家性别
    self.money = 0 --玩家财富，金币，排行榜需要
    self.product = 0 --玩家产出，排行榜需要
    self.click = 0 --玩家点击， 排行榜需要
    self.rewardState = 1 --邀请有礼的奖励状态 1-未达成, 2-可领取, 3-已领取
end

function UserFriendSimpleData:GetDBTable()
    local tmp = { }
    tmp.name = self.name
    tmp.signature = self.signature
    tmp.area = self.area
    tmp.horoscope = self.horoscope
    tmp.head = self.head
    tmp.star = self.star
    tmp.sex = self.sex
    tmp.money = self.money
    tmp.protduct = self.product
    tmp.click = self.click
    tmp.rewardState = self.rewardState
    return tmp
end

function UserFriendSimpleData:SetDBTable(tmp)
    if tmp == nil then return end
    self.name = tmp.name or ""
    self.signature = tmp.signature or ""
    self.area = tmp.area or ""
    self.horoscope = tmp.horoscope or ""
    self.head = tmp.head or ""
    self.star = tmp.star or 1
    self.sex = tmp.sex or 1
    self.money = tmp.money or 0
    self.product = tmp.product or 0
    self.click = tmp.click or 0
    self.rewardState = tmp.rewardState or 1
end


--玩家好友信息初始化
function UserFriend:Init(uid)
    -- 创建好友结构体
    self.uid = uid
    self.app_id = ""
    self.online = true --当前玩家是否在线
    self.simpleData = UserFriendSimpleData:New()     --玩家简单数据，用于显示
    self.simpleData:Init()

    -- 好友的全部好友数据存这里，映射  好友uid---对应---FriendData单个好友数据
    self.friends = Map:New()
    self.friends:Init()

    --邀请加玩家为好友的玩家队列， 主要用于玩家下线期间， 玩家被邀请为好友， 无法及时回答对方
    --这里只是简单映射下, uid--boolean
    self.askAddFriends = Map:New()
    self.askAddFriends:Init()

    --今天邀请过的玩家，不能再被邀请
    --这里只是简单映射下, uid--boolean
    self.todayAskedFriends = Map:New()
    self.todayAskedFriends:Init()

    -- 最后一次邀请玩家的时间, 用于第二天清楚todayAskedFriends数据
    self.lastAskFriendsTime = 0
    
    -- 当天系统推荐好友队列
    --这里只是简单映射下, uid--boolean
    self.recommendFriends = Map:New()
    self.recommendFriends:Init()

    -- 被删除的QQ好友，下次登入时不再被重新加入
    self.deleteQQFriend = Map:New()
    self.deleteQQFriend:Init()
    
    -- 上一次推荐好友的时间 用于当天推荐好友不重复
    self.lastRecommendTime = 0

    -- 旅行团数据
    self.userTravel = UserTravel:New()
    self.userTravel:Init(uid)

    -- change判断数据是否改变，用来存取DB
    self.change = false

    -- 玩家上次离线时间, 用来
    self.lastLogoutTime = 0

    -- 邀请你来玩游戏的玩家UID
    self.askMePlayGameUid = 0

    -- 你邀请的来玩游戏的玩家UID
    self.meAskPlayerUids = { }

    -- 你邀请的来玩游戏的玩家UID，且为首次登陆
    self.meAskPlayerUidsAndFirstLogin = { }

    -- autorecommendtimer 自动推荐定时器
    self.autorecommendtimer = nil

    --CheckData 定时器
    self.checkdatatimer = nil
end

function UserFriend:GetAskMePlayGameUid()
    return self.askMePlayGameUid
end

--邀请的好友首次登陆
function UserFriend:AddMeAskPlayerUidsAndFirstLogin(uid)

    unilight.debug("table.getn(self.meAskPlayerUids), add-->uid="..uid..", self.uid="..self.uid)

    if table.getn(self.meAskPlayerUids) >= 10 then
        unilight.debug("table.getn(self.meAskPlayerUids) >= 10")
        return
    end

    for i, v in ipairs(self.meAskPlayerUidsAndFirstLogin) do
        if v == uid then
            unilight.debug("AddMeAskPlayerUidsAndFirstLogin, self.uid="..self.uid..", addUid="..uid..", already exist")
            return
        end
    end

    table.insert(self.meAskPlayerUidsAndFirstLogin, uid)

    for i, v in ipairs(self.meAskPlayerUidsAndFirstLogin) do
        print("self.uid="..self.uid..", AddMeAskPlayerUidsAndFirstLogin, i="..i..", v="..v..", newUid="..v)
    end
end

function UserFriend:SetAskMePlayGameUid(uid)
    self.askMePlayGameUid = uid
end

function UserFriend:AddMeAskPlayerUids(uid)
    table.insert(self.meAskPlayerUids, uid)
end

function UserFriend:GetMeAskPlayerUidsAndFirstLogin()
    return self.meAskPlayerUidsAndFirstLogin
end

--获得你邀请的玩家UID
function UserFriend:GetMeAskPlayerUids()
    return self.meAskPlayerUids
end

--获得言论
function UserFriend:GetSignature()
    return self.simpleData.signature
end

--获得地区，字符串
function UserFriend:GetArea()
    return self.simpleData.area
end

--获得星座，数字，配置表数据
function UserFriend:GetHoroscope()
    return self.simpleData.horoscope
end

--获得star,数字
function UserFriend:GetStar()
    return self.simpleData.star
end

function UserFriend:SetStar(star)
    self.simpleData.star = star
end

--获得sex,数字，1标识男性
function UserFriend:GetSex()
    return self.simpleData.sex
end

function UserFriend:SetSex(sex)
    self.simpleData.sex = sex
end

--获得财富，排行榜需要
function UserFriend:GetMoney()
    return self.simpleData.money
end

function UserFriend:SetMoney(money)
    self.simpleData.money = money
end

function UserFriend:GetProduct()
    return self.simpleData.product
end

function UserFriend:GetClick()
    return self.simpleData.click
end

function UserFriend:GetRewardState()

    unilight.debug("GetRewardState, rewardState="..self.simpleData.rewardState..", star="..self.simpleData.star..", Invitation_Star_Awardse="..GlobalConst.Invitation_Star_Awardse)
    if self.simpleData.rewardState == 1 and self.simpleData.star >= GlobalConst.Invitation_Star_Awardse then
        self.simpleData.rewardState = 2
    end

    return self.simpleData.rewardState
end

function UserFriend:SetRewardState(rewardState)
    self.simpleData.rewardState = rewardState
end

--head name 数据暂时不对
function UserFriend:SetUserSimpleData(star, sex, signature, area, horoscope)
    self.simpleData.star = star or 0
    self.simpleData.sex = sex or 1
    self.simpleData.signature = signature or ""
    self.simpleData.area = area or ""
    self.simpleData.horoscope = horoscope or ""
end

function UserFriend:IsDeleteUserFriendFromMemory()
    if self:GetLastLogoutTime() ~= 0 and self:GetOnline() == false then
        if self:GetLastLogoutTime() + static_const.Static_Const_Friend_MAX_ONLINE_TIME_AFTER_OFFLINE < os.time() then
            return true
        end
    end
    return false
end

function UserFriend:ClearTravelInfo()
    self.userTravel:ClearCaptureInfo()
    local out = self.userTravel:ClearOutTimeMember()

    for uid, v in pairs(out) do
        if self:GetOnline() == true then
            --在线的话通知对方
            local req = { }
            req["do"] = "Cmd.NotifyUserTravelTimeOut_S"
            req["data"] = { 
                uid = uid,
            }
            req.errno = unilight.SUCCESS
            local laccount = go.roomusermgr.GetRoomUserById(self.uid)
            if laccount == nil then
                unilight.debug("sorry, the laccount of the ask_uid:" .. self.uid .. " is nil")
            else
                unilight.success(laccount, req)
            end
        end
    end
end

function UserFriend:GetUserTravel()
    return self.userTravel
end

--将从db里取出来的一个table数据放到userfriend里
function UserFriend:SetDBTable(data)
    self.uid = data.uid or 0
    self.app_id = data.app_id or ""
    self.online = data.online or false
    self.simpleData:SetDBTable(data.simpleData)

    if data.friends ~= nil then
        for k,v in pairs(data.friends) do
            local friend = FriendData:New()
            friend:Init(v.uid, v.head, v.name, v.app_id, v.isQQFriend)
            self.friends:Insert(k, friend)
        end
    end

    if data.askAddFriends ~= nil then
        for k,v in pairs(data.askAddFriends) do
            self.askAddFriends:Insert(k,v)
        end
    end

    if data.todayAskedFriends ~= nil then
        for k,v in pairs(data.todayAskedFriends) do
            self.todayAskedFriends:Insert(k,v)
        end
    end

    self.lastAskFriendsTime = data.lastAskFriendsTime or 0

    if data.recommendFriends ~= nil then
        for k,v in pairs(data.recommendFriends) do
            self.recommendFriends:Insert(k,v)
        end
    end

    self.lastRecommendTime = data.lastRecommendTime or 0

    if data.deleteQQFriend ~= nil then
        for k,v in pairs(data.deleteQQFriend) do
            self.deleteQQFriend:Insert(k,v)
        end
    end

    if data.meAskPlayerUidsAndFirstLogin ~= nil then
        self.meAskPlayerUidsAndFirstLogin = data.meAskPlayerUidsAndFirstLogin
    end

    self.userTravel:SetDBTable(data.userTravel)
end

--将userfriend数据打包到一个table里
function UserFriend:GetDBTable()
    local data = {}
    data.uid = self.uid
    data.app_id = self.app_id
    data.online = self.online
    data.simpleData = self.simpleData:GetDBTable()

    data.friends = {}
    self.friends:ForEach(
        function(k,v)
            data.friends[k] = v:GetDBTable()
        end
    )

    data.askAddFriends = {}
    self.askAddFriends:ForEach(
        function(k,v)
            data.askAddFriends[k] = v
        end
    )
    
    data.todayAskedFriends = {}
    self.todayAskedFriends:ForEach(
        function(k,v)
            data.todayAskedFriends[k] = v
        end
    )

    data.lastAskFriendsTime = self.lastAskFriendsTime

    data.recommendFriends = {}
    self.recommendFriends:ForEach(
        function(k,v)
            data.recommendFriends[k] = v
        end
    )

    data.deleteQQFriend = { }
    data.lastRecommendTime = self.lastRecommendTime

    self.deleteQQFriend:ForEach(
        function(k,v)
            data.deleteQQFriend[k] = v
        end
    )

    data.meAskPlayerUidsAndFirstLogin = self.meAskPlayerUidsAndFirstLogin

    data.userTravel = self.userTravel:GetDBTable()

    return data
end

function UserFriend:RecommendFriendForEach(fun, ...)
    self.recommendFriends:ForEach(fun, ...)
end

function UserFriend:AddRecommendFriends(uid)
    self.recommendFriends:Insert(uid, true)
    self.lastRecommendTime = os.time()
end

function UserFriend:IsRecommendedToFriend(uid)
    if self.recommendFriends:Find(uid) == nil then
        return false
    else
        return true
    end
end

function UserFriend:DelRecommendFriends(uid)
    self.recommendFriends:Remove(uid)
end

function UserFriend:ClearRecommendFriends()
    if common.IsSameDay(self.lastRecommendTime, os.time()) == false then
        self.todayAskedFriends:Clear()
        self.lastRecommendTime = os.time()
    end
end

function UserFriend:SetBaseInfo(uid, head, name, app_id, sex)
    self.uid = uid or ""
    self.app_id = app_id or ""
    self.simpleData.name = name or ""
    self.simpleData.head = head or ""
    self.simpleData.sex = sex or 1
end

function UserFriend:PrintBaseInfo()
    unilight.debug("--------Print User Friend Base Info:-----------------")
    unilight.debug("uid:" .. self.uid)
    unilight.debug("head:" .. self.simpleData.head)
    unilight.debug("name:" .. self.simpleData.name)
    unilight.debug("area:" .. self.simpleData.area)
    unilight.debug("star:" .. self.simpleData.star)
    unilight.debug("app_id:" .. self.app_id)
end

function UserFriend:PrintUserFriend()
    unilight.debug("打印玩家(" .. self.simpleData.name .. ")好友信息:")
    self.friends:ForEach(
        function(k,v)
            v:PrintData()
        end
    )
end

function UserFriend:PrintAlInfo()
    self:PrintBaseInfo()
    self:PrintUserFriend()
    unilight.debug("打印玩家不在线，邀请该玩家的好友UID：")
    self.askAddFriends:ForEach(
        function(k,v)
            unilight.debug(tostring(k))
        end
    )
    unilight.debug("打印今天邀请过的玩家UID:")
    self.todayAskedFriends:ForEach(
        function(k,v)
            unilight.debug(tostring(k))
        end
    )
    unilight.debug("打印今天推荐过的好友UID：")
    self.recommendFriends:ForEach(
        function(k,v)
            unilight.debug(tostring(k))
        end
    )
    unilight.debug("打印删除了的QQ好友UID:")
    self.deleteQQFriend:ForEach(
        function(k,v)
            unilight.debug(tostring(k))
        end
    )
end

function UserFriend:GetUid()
    return self.uid
end

function UserFriend:GetHead()
    return self.simpleData.head
end

function UserFriend:SetHead(head)
    self.simpleData.head = head
end

function UserFriend:GetName()
    return self.simpleData.name
end

function UserFriend:SetName(name)
    self.simpleData.name = name
end

function UserFriend:GetAppId()
    return self.app_id
end

function UserFriend:GetOnline()
    return self.online
end

function UserFriend:SetOnline()
    self.online = true
end

function UserFriend:SetOffline()
    self.online = false
end

function UserFriend:GetLastLogoutTime()
    return self.lastLogoutTime
end

function UserFriend:SetLastLogoutTime()
    self.lastLogoutTime = os.time()
end

function UserFriend:ClearLastLogoutTime()
    self.lastLogoutTime = 0
end


-- 添加好友消息
function UserFriend:AddUserFriend(uid, head, name, app_id, isQQFriend)
    local friend = FriendData:New()
    friend:Init(uid, head, name, app_id, isQQFriend)
    self.friends:Insert(uid, friend)
    return friend
end

function UserFriend:GetFriendsCount()
    return self.friends:Count()
end

-- 获取一个好友的数据
function UserFriend:GetUserFriend(uid)
    return self.friends:Find(uid)
end

-- 删除单个好友
function UserFriend:DelUserFriend(uid)
    self.friends:Remove(uid)
end

-- 获取好友所有好友信息 
function UserFriend:UserFriendsForEach(fun, ...)
    self.friends:ForEach(fun, ...)
end

--邀请加玩家为好友的玩家队列， 主要用于玩家下线期间， 玩家被邀请为好友， 无法及时回答对方
function UserFriend:AddAskAddFriends(uid)
    self.askAddFriends:Insert(uid, true)
end

function UserFriend:DelAskAddFriends(uid)
    self.askAddFriends:Remove(uid)
end

--是否在被邀请队列中
function UserFriend:IsExistAskAddFriends(uid)
    if self.askAddFriends:Find(uid) == nil then
        return false
    else
        return true
    end
end

--轮询被邀请玩家队列
function UserFriend:AskAddFriendsForEach(fun, ...)
    self.askAddFriends:ForEach(fun, ...)
end

--清理被邀请对垒
function UserFriend:ClearAskAddFriends()
    self.askAddFriends:Clear()
end

--今天邀请过的玩家，不能再被邀请
function UserFriend:AddTodayAskedFriends(uid)
    self.todayAskedFriends:Insert(uid, true)
    self.lastAskFriendsTime = os.time()
end

--是否在今天邀请过的队列中
function UserFriend:IsExistTodayAskedFriends(uid)
    if self.todayAskedFriends:Find(uid) == nil then
        return false
    else
        return true
    end
end

function UserFriend:DelTodayAskedFriends(uid)
    self.todayAskedFriends:Remove(uid)
end

function UserFriend:ClearTodayAskedFriends()
    if common.IsSameDay(self.lastAskFriendsTime, os.time()) == false then
        self.todayAskedFriends:Clear()
        self.lastAskFriendsTime = os.time()
    end
end

-- 被删除的QQ好友，下次登入时不再被重新加入
function UserFriend:AddDeleteQQFriend(uid)
    self.deleteQQFriend:Insert(uid, true)
end

function UserFriend:DelDeleteQQFriend(uid)
    self.deleteQQFriend:Remove(uid)
end

function UserFriend:IsExistDeleteQQFriend(uid)
    if self.deleteQQFriend:Find(uid) == nil then
        return false
    else
        return true
    end
end