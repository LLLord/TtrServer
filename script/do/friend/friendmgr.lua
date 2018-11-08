require "script/gxlua/class"
require "script/do/common/staticconst"
require "script/do/UserInfo"

CreateClass("FriendManager")    --好友数据结构管理

--初始化，分配好友数据
function FriendManager:Init()
    --data 映射 data为一个UID映射好友数据
   self.userFriend = Map:New()
   self.userFriend:Init()
   --用来做随机推荐
   self.friendUidList = {}

   -- QQ唯一标识，存取app_id对应的头像，名字，以及在游戏中的uid
   self.userQQInfo = Map:New()
   self.userQQInfo:Init()

   self:LoadQQInfoFromDB()
   self:LoadAllUserFriendData()

   unilight.addtimer("FriendManager.SaveUserFriendToDB",static_const.Static_Const_Friend_Save_Data_To_DB_Time)
end

--存取QQ唯一标识数据
function FriendManager:SaveUserQQInfo(app_id, uid)
    if self.userQQInfo:Find(app_id) ~= nil then
        self.userQQInfo:Replace(app_id, uid)
        return
    end

   self.userQQInfo:Insert(app_id, uid)
   local tmp = {
       app_id = app_id,
       uid = uid,
   }
   unilight.savedata("userQQAppId", tmp)
end

function FriendManager:PrintUserQQInfo()
    unilight.debug("---------Print User QQ Info:-----------")
    self.userQQInfo:ForEach(
        function(k,v)
            unilight.debug("app_id:" .. k .. "...........uid:" .. v)
        end
    )
end

function FriendManager:LoadQQInfoFromDB()
    unilight.debug("服务器启动时从数据库加载所有QQAppId信息.............")
    local tmp = unilight.getAll("userQQAppId")
    for i, info in ipairs(tmp) do
        self.userQQInfo:Insert(info.app_id, info.uid)
    end
end

--为了方便测试
function FriendManager:LoadAllUserFriendData()
    unilight.debug("服务器启动时从数据库加载所有玩家好友数据信息(方便测试).............")
    local tmp = unilight.getAll("friendinfo")
    for i, info in ipairs(tmp) do
        friendData = UserFriend:New()
        friendData:Init(info.uid)
        friendData:SetDBTable(info)
        friendData:SetLastLogoutTime()
        self.userFriend:Insert(info.uid, friendData)
        RankListMgr:UpdateRankNode(RankListMgr.rank_type_star, friendData:GetUid(), friendData:GetStar())
        RankListMgr:UpdateRankNode(RankListMgr.rank_type_money, friendData:GetUid(), friendData:GetMoney())
        RankListMgr:UpdateRankNode(RankListMgr.rank_type_product, friendData:GetUid(), friendData:GetProduct())
        RankListMgr:UpdateRankNode(RankListMgr.rank_type_click, friendData:GetUid(), friendData:GetClick())
        table.insert(self.friendUidList, info.uid)
    end
end

function FriendManager:PrintAllUserFriendInfo()
    unilight.debug("---------Print All User Friend Info:-----------")
    self.userFriend:ForEach(
        function(k,v)
            v:PrintBaseInfo()
        end
    )
end

-- 获得QQ唯一标识数据
function FriendManager:GetUserQQInfo(app_id)
   return self.userQQInfo:Find(app_id)
end

-- 获取或创建玩家好友信息
function FriendManager:GetOrNewFriendInfo(uid)
    local friendData = self.userFriend:Find(uid)

    --如果为空 则新建
    if friendData == nil then
        unilight.debug("构建玩家好友数据uid:" .. uid)
        friendData = UserFriend:New()
        friendData:Init(uid)

        unilight.debug("从DB数据库拉取数据uid:" .. uid)

        local ret = self:LoadDataFromDb(friendData)
        if ret == nil then
            unilight.debug("玩家好友数据第一次创建，立马存DB")
            self:SaveDataToDb(friendData)
        end
        if friendData:GetOnline() == false then
            friendData:SetLastLogoutTime()
        end
        self.userFriend:Insert(uid, friendData)
        table.insert(self.friendUidList, uid)
    end
    return friendData
end

function FriendManager:SaveDataToDb(friendData)
    if friendData == nil then return end

    local t = friendData:GetDBTable()
    unilight.savedata("friendinfo", t)
end

function FriendManager:LoadDataFromDb(friendData)
    if friendData == nil then return nil end
    
    local data = unilight.getdata("friendinfo", friendData.uid)
    if data == nil then
        unilight.debug("uid:" .. friendData.uid .. "好友数据在数据库中不存在")
        return nil
    end
    friendData:SetDBTable(data)
    return friendData
end

function FriendManager:LoadDataFromDbByUid(uid)
    local data = unilight.getdata("friendinfo", uid)
    if data == nil then
        unilight.debug("uid:" .. uid .. "好友数据在数据库中不存在")
        return nil
    end
    unilight.debug("uid:" .. uid .. "从数据库加载好友数据................")
    local friendData = UserFriend:New()
    friendData:Init(uid)
    friendData:SetDBTable(data)
    return friendData
end

-- 获取玩家好友信息如果不存在的话，从DB里拉取数据
function FriendManager:GetFriendInfo(uid)
    local friendData = self.userFriend:Find(uid)
    if friendData == nil then
        friendData = self:LoadDataFromDbByUid(uid)
        if friendData ~= nil then
            if friendData:GetOnline() == false then
                friendData:SetLastLogoutTime()
            end
            self.userFriend:Insert(uid, friendData)
            table.insert(self.friendUidList, uid)
        end
    end
    return friendData
end

--考虑到性能，一些情况下只考虑内存中存在的数据
function FriendManager:GetFriendInfoFromMemory(uid)
    return self.userFriend:Find(uid)
end

function FriendManager:FriendInfoForEach(fun, ...)
    self.userFriend:ForEach(fun, ...)
end

function FriendManager:DelFriendInfoFromMemory(uid)
    self.userFriend:Remove(uid)
    for i, _uid in ipairs(self.friendUidList) do
        if _uid == uid then
            table.remove(self.friendUidList, i)
            return
        end
    end
end

function FriendManager:GetRandomFriendInfo()
    local index = math.random(1, #self.friendUidList)
    local uid = self.friendUidList[index]
    if uid ~= nil then
        return FriendManager:GetFriendInfo(uid)
    end
end

-- 系统自动推荐好友
function FriendManager.SystemAutoRecommendFriend(uid, timer)
    local friendData = FriendManager:GetOrNewFriendInfo(uid)
    local travelData = friendData:GetUserTravel()
    
    local res = { }
    res["do"] = "Cmd.SystemAutoRecommendFriendCmd_S"
    for i=0,100,1  do
        local data = FriendManager:GetRandomFriendInfo()
        if data ~= nil and data:GetUid() ~= uid and data:GetOnline() == true and friendData:GetUserFriend(data:GetUid()) == nil then
            res["data"] = {
                uid = data:GetUid(),
                head = data:GetHead(),
                name = data:GetName(),
                star =  data:GetStar(), 
                sex =  data:GetSex(), 
                signature =  data:GetSignature(), 
                area =  data:GetArea(), 
                horoscope =  data:GetHoroscope(),
                friend_ship = travelData:GetRelationShip(data:GetUid()),
            }
            res.errno = unilight.SUCCESS
            local ask_laccount = go.roomusermgr.GetRoomUserById(uid)
            if ask_laccount == nil then
                unilight.debug("sorry, the laccount of the uid:" .. uid .. " is nil")
            else
                unilight.success(ask_laccount, res)
            end
            return
        end
    end
    
end

function FriendManager.SaveUserFriendToDB(timer)
    FriendManager:FriendInfoForEach(
        function(uid,info)
            FriendManager:SaveDataToDb(info)
        end
    )
end

--每隔一段时间，查看好友数据，是否需要更新
function FriendManager.CheckData(uid, timer)
    local friendData = FriendManager:GetFriendInfoFromMemory(uid)

    friendData:ClearTravelInfo()

    if friendData:IsDeleteUserFriendFromMemory() == true then
        unilight.debug("玩家(" .. friendData:GetName() .. ")离线时间过长(" .. (os.time() - friendData:GetLastLogoutTime()) .. ")，数据下线")
        FriendManager:SaveDataToDb(friendData)
        FriendManager:DelFriendInfoFromMemory(uid)
        friendData:PrintBaseInfo()
        unilight.stoptimer(timer)
        friendData.checkdatatimer = nil
    end
end

-- 玩家上线
function FriendManager:UserLoginFriend(uid)
    local friendData = self:GetOrNewFriendInfo(uid)
    friendData:SetOnline()
    friendData:ClearLastLogoutTime()

    friendData:ClearTodayAskedFriends()
    friendData:ClearRecommendFriends()
    friendData:ClearTravelInfo()

    if friendData.autorecommendtimer == nil then
        friendData.autorecommendtimer = unilight.addtimer("FriendManager.SystemAutoRecommendFriend", static_const.Static_Const_Friend_System_Auto_Recommend_Time, uid)
    end

    if friendData.checkdatatimer == nil then
        friendData.checkdatatimer = unilight.addtimer("FriendManager.CheckData", static_const.Static_Const_Friend_System_Check_Data_Time, uid)
    end

    friendData:PrintBaseInfo()
    return friendData
end

-- 玩家下线
function FriendManager:UserLogoutFriend(uid)
    local friendData = self:GetOrNewFriendInfo(uid)
    friendData:SetOffline()
    friendData:SetLastLogoutTime()

    if friendData.autorecommendtimer ~= nil then
        unilight.stoptimer(friendData.autorecommendtimer)
    end

    --local userInfo = UserInfo.GetUserInfoById(uid)
    --if userInfo ~= nil and userInfo.settings ~= nil then
    --    friendData:SetUserSimpleData(userInfo.nickName, userInfo.headUrl, userInfo.star, userInfo.gender, userInfo.settings.signature, userInfo.settings.area, userInfo.settings.horoscope)
    --end
end