Net.CmdReqGetWorldRankListInfo_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.ReqGetWorldRankListInfo_S"

    --检查客户端输入
    if cmd["data"] == nil or type(cmd["data"].rank_type) ~= "number" or 
    type(cmd["data"].start_index) ~= "number" or 
    type(cmd["data"].end_index) ~= "number" then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    local rankType = cmd["data"].rank_type
    local startIndex = cmd["data"].start_index
    local endIndex = cmd["data"].end_index

    if startIndex > endIndex then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res    
    end

    local uid = laccount.Id
    local friendData = FriendManager:GetOrNewFriendInfo(uid);
    local travelData = friendData:GetUserTravel()

    local data = RankListMgr:ReqGetData(rankType)

    if data == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据rankType出错"
        }
        return res
    end

    res["data"] = {}
    res["data"].rank_node = {}
    res["data"].rank_type = rankType

    local rankList = RankListMgr:GetRankList(rankType)
    if rankList ~= nil then
        local self_node = rankList:GetNode(uid)
        if self_node ~= nil then
            res["data"].self_node = {
                uid = self_node:GetUid(),
                value = self_node:GetValue(),
                name = friendData:GetName(),
                head = friendData:GetHead(),
                sex = friendData:GetSex(),
                star = friendData:GetStar(),
                signature =  friendData:GetSignature(), 
                area =  friendData:GetArea(), 
                horoscope =  friendData:GetHoroscope(),
                friend_ship = travelData:GetRelationShip(self_node:GetUid()),
                rank = self_node:GetRank(),
            } 
        end
    end

    if startIndex > 100 then
        return res
    end

    if endIndex > 100 then
        endIndex = 100
    end

    for index=startIndex, endIndex do
        local node = data[index]
        if node == nil then 
            return res
        end
        local node_friendData = FriendManager:GetFriendInfo(node:GetUid());
        if node_friendData ~= nil then
            local tmp = {
                uid = node:GetUid(),
                value = node:GetValue(),
                name = node_friendData:GetName(),
                head = node_friendData:GetHead(),
                sex = node_friendData:GetSex(),
                star = node_friendData:GetStar(),
                signature =  node_friendData:GetSignature(), 
                area =  node_friendData:GetArea(), 
                horoscope =  node_friendData:GetHoroscope(),
                friend_ship = travelData:GetRelationShip(node:GetUid()),
                rank = node:GetRank(),
            }
            table.insert(res["data"].rank_node, tmp)
        end
    end

    return res
end