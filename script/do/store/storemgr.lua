require "script/gxlua/class"

local StoreData = StoreData
local ItemData = ItemData

--玩家商品
UserItems =
{
        owner = nil,
	buyitems = {},
	rechargeitems = {},
}

function UserItems:new(o)
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
end

function UserItems:init(owner)
        self.owner = owner
	self.buyitems = {}
	self.rechargeitems = {}
end

function UserItems:setDBTable(data)
	unilight.debug("------110")
	if data == nil then
		unilight.warn("No UserItems")
		return false
	end
	self.buyitems = data.buyitems
	self.rechargeitems = data.rechargeitems	
	unilight.debug("------110" .. #self.buyitems .. "------".. #self.rechargeitems)
end

function UserItems:GetDBTable()
        local data = {}
        data.buyitems = self.buyitems
        data.rechargeitems = self.rechargeitems
        return data
end

function UserItems:checkIsFirstRecharge(goodsid)
	for k, v in pairs(self.rechargeitems) do
		if v == goodsid then
			return false
		end
	end
	return true
end

function UserItems:addRechargeItems(goodsid)
	for k, v in pairs(self.rechargeitems) do
		if v == goodsid then
			return 
		end
	end
	if goodsid then
		table.insert(self.rechargeitems, goodsid)
		unilight.savefield("userinfo", self.owner.uid, "UserItems.rechargeitems", self.rechargeitems)	
	end
end


function UserItems:checkUserHadItem(goodsid)
	unilight.debug("------005")
	for k, v in pairs(self.buyitems) do
		if v == goodsid then
	unilight.debug("------006")
			return true
		end
	end
	unilight.debug("------007")
	return false
end

function UserItems:addUserItems(goodsid)
	unilight.debug("------001")
	for k, v in pairs(self.buyitems) do
		if v == goodsid then
			return 
		end
	end
	unilight.debug("------002")
	if goodsid then
	unilight.debug("------003")
		table.insert(self.buyitems, goodsid)
		unilight.savefield("userinfo", self.owner.uid, "UserItems.buyitems", self.buyitems)	
		return true
	end
	return false
end

function UserItems:removeUserItems(goodsid)
	if goodsid then
		table.remove(self.buyitems, goodsid)
		return true
	end
	return false
end
function UserItems:getUserHadBuyGoods()
	unilight.debug("------0000000000 size:" .. #self.buyitems)
	return self.buyitems
end

function UserItems:useItem(userinfo,itemid,itemnum)
--	unilight.debug("userItem-001" .. " itemid:" .. itemid .. " itemnum:" .. itemnum)
	if userinfo == nil or itemid == nil or itemid == 0 then
		return false
	end
	if itemnum == 0 then
		itemnum = 1
	end
	local itemdata = ItemData[itemid]
	if not itemdata then
		unilight.debug("2222" .. " itemid:" .. itemid .. " itemnum:" .. itemnum)
		return false
	end
	local itemtype = tonumber(itemdata.itemtype)
	--这里是玩家购买了旅行团头像后的回调
	if itemtype == static_const.Static_ItemType_Clothes then
		UserTravel.AddTravelHeadBackupCallBack(userinfo.uid,itemid,itemnum)
	end

	--旅行团护盾
	if itemtype == static_const.Static_ItemType_ProtectTimes then
		UserTravel.BuyShieldCountCallBack(userinfo.uid,itemid,itemnum)
	end
	
	UserProps:setUserProp(userinfo,itemtype, itemnum, tonumber(itemdata.paraone), tonumber(itemdata.paratwo))
	unilight.debug("2221" .. " itemid:" .. itemid .. " itemnum:" .. itemnum .. " itemtype" .. itemtype)
	--处理打开获得道具
	local items = itemdata.openitems
	local args = string.split(items, ';')
	for k,v in pairs(args) do
		local aargs = string.split(v, '_')
		local aitemid = aargs[1]
		local aitemnum = aargs[2]
		UserItems:useItem(userinfo,tonumber(aitemid),tonumber(aitemnum))
	end
	unilight.debug("userItem-009" .. " itemid:" .. itemid .. " itemnum:" .. itemnum)
end

--玩家属性
UserProps =
{
        owner = nil,
	props = {
	pProtectTimes = 0, --护盾次数
	pPower = 0,	   --能量值	
	pGoldPerSecond = 0,	--每秒当前金币产量
	pBuildingProduceRate = 0,	--建筑生产速度
	pClickGoldAdd = 0,		--每次点击增加金币
	pWorldGoldAdd = 0,		--世界每秒增加金币
	pAutoClickTimes_Time = 0, 	--世界每秒增加金币的时间
	pAutoClickTimes_Times = 0,	--世界每秒增加金币的次数
	pWeekCardEndTime = 0,		--周卡结束时间
	pMonthCardEndTime = 0,		--月卡结束时间
	pClothes = {},			--时装
	pClickGoldAddRatio = 0,		--点击金币加成
	pWorldGoldAddRatio = 0,		--世界金币加成
	pGoldRainTimeAdd = 0,		--金币雨时间加成
	pOfflineGoldAddRatio = 0,	--离线金币加成
	}
}

function UserProps:new(o)
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
end

function UserProps:init(owner)
        self.owner = owner
	self.props = {	
	pProtectTimes = 0, --护盾次数
	pPower = 0,	   --能量值	
	pGoldPerSecond = 0,	--每秒当前金币产量
	pBuildingProduceRate = 0,	--建筑生产速度
	pClickGoldAdd = 0,		--每次点击增加金币
	pWorldGoldAdd = 0,		--世界每秒增加金币
	pAutoClickTimes_Time = 0, 	--世界每秒增加金币的时间
	pAutoClickTimes_Times = 0,	--世界每秒增加金币的次数
	pWeekCardEndTime = 0,		--周卡结束时间
	pMonthCardEndTime = 0,		--月卡结束时间
	pClothes = {},			--时装
	pClickGoldAddRatio = 0,		--点击金币加成
	pWorldGoldAddRatio = 0,		--世界金币加成
	pGoldRainTimeAdd = 0,		--金币雨时间加成
	pOfflineGoldAddRatio = 0,	--离线金币加成
	}
end

function UserProps:setDBTable(data)
	if data == nil then
		unilight.warn("No UserProps")
		return false
	end
	self.props = data
end

function UserProps:GetDBTable()
        local data = {}
        data.props = self.props
        return data
end

function UserProps:sendUserProps()
	local res = { }
	res["do"] = "Cmd.SendUserPropertyOnUseItemCmd_S"
	res["data"] = {
			pProtectTimes = self.props.pProtectTimes,			
			pPower = self.props.pPower,			
			pGoldPerSecond = self.props.pGoldPerSecond,			
			pBuildingProduceRate = self.props.pBuildingProduceRate,			
			pClickGoldAdd = self.props.pClickGoldAdd,			
			pWorldGoldAdd = self.props.pWorldGoldAdd,			
			pAutoClickTimes_Time = self.props.pAutoClickTimes_Time,			
			pAutoClickTimes_Times = self.props.pAutoClickTimes_Times,			
			pWeekCardEndTime = self.props.pWeekCardEndTime,			
			pMonthCardEndTime = self.props.pMonthCardEndTime,			
			pClothes = self.props.pClothes,			
			pClickGoldAddRatio = self.props.pClickGoldAddRatio,			
			pWorldGoldAddRatio = self.props.pWorldGoldAddRatio,			
			pGoldRainTimeAdd = self.props.pGoldRainTimeAdd,			
			pOfflineGoldAddRatio = self.pOfflineGoldAddRatio,			
	}
	unilight.response(self.owner.laccount, res)		
end

function UserProps:setUserProp(userinfo,itemtype,itemnum,paraone,paratwo)
	unilight.debug("3330" .. " itemtype:" .. itemtype .. " paraone:" .. paraone .. " paratwo" .. paratwo)
	if userinfo == nil then
		return 
	end
	if tonumber(paraone) == 0 then
		paraone = 1
	end

	local mailid = 0
	local res = { }
	res["do"] = "Cmd.SendUserPropertyOnUseItemCmd_S"
	if itemtype == tonumber(static_const.Static_ItemType_Diamond) then
		UserInfo.AddUserMoney(userinfo, static_const.Static_MoneyType_Diamond, itemnum)
	elseif itemtype == tonumber(static_const.Static_ItemType_Gold) then
		UserInfo.AddUserMoney(userinfo, static_const.Static_MoneyType_Gold, itemnum)
	elseif itemtype == tonumber(static_const.Static_ItemType_Rmb) then

	elseif itemtype == tonumber(static_const.Static_ItemType_ProtectTimes) then
		self.props.pProtectTimes = self.props.pProtectTimes + itemnum*paraone  
		res["data"] = {
			pProtectTimes = self.props.pProtectTimes			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_Power) then
		self.props.pPower = self.props.pPower + itemnum*paraone  
		res["data"] = {
			pPower = self.props.pPower			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_GoldPerSecond) then
--[[
		self.props.pGoldPerSecond = self.props.pGoldPerSecond + itemnum*paraone  
		res["data"] = {
			pGoldPerSecond = self.props.pGoldPerSecond			
		}]]--
	elseif itemtype == tonumber(static_const.Static_ItemType_BuildingProduceRate) then
		self.props.pBuildingProduceRate = self.props.pBuildingProduceRate + itemnum*paraone  
		res["data"] = {
			pBuildingProduceRate = self.props.pBuildingProduceRate			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_ClickGoldAdd) then
		self.props.pClickGoldAdd = self.props.pClickGoldAdd + itemnum*paraone  
		res["data"] = {
			pClickGoldAdd = self.props.pClickGoldAdd			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_WorldGoldAdd) then
		self.props.pWorldGoldAdd = self.props.pWorldGoldAdd + itemnum*paraone  
		res["data"] = {
			pWorldGoldAdd = self.props.pWorldGoldAdd			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_AutoClick) then
		self.props.pAutoClickTimes_Time = self.props.self.props.pAutoClickTimes_Time + itemnum*paraone*60
		self.props.pAutoClickTimes_Times = self.props.self.props.pAutoClickTimes_Times + itemnum*paratwo
		res["data"] = {
			pAutoClickTimes_Time = self.props.pAutoClickTimes_Time,			
			pAutoClickTimes_Times = self.props.pAutoClickTimes_Times			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_WeekCard) then
		if self.props.pAutoClickTimes_Times then
			self.props.pWeekCardEndTime = self.props.pWeekCardEndTime + itemnum*paraone*86400  
		else	
			self.props.pWeekCardEndTime = os.time() + itemnum*paraone*86400	
		end
		res["data"] = {
			pWeekCardEndTime = self.props.pWeekCardEndTime			
		}
		mailid=8
	elseif itemtype == tonumber(static_const.Static_ItemType_MonthCard) then
		if self.props.pAutoClickTimes_Times then
			self.props.pMonthCardEndTime = self.props.pMonthCardEndTime + itemnum*paraone*86400 
		else	
			self.props.pMonthCardEndTime = os.time() + itemnum*paraone*86400	
		end
		res["data"] = {
			pMonthCardEndTime = self.props.pMonthCardEndTime			
		}
		mailid=9
	elseif itemtype == tonumber(static_const.Static_ItemType_Clothes) then
		table.insert(self.props.pClothes, itemid)
		res["data"] = {
			pClothes = self.props.pClothes			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_ClickGoldAddRatio) then
		self.props.pClickGoldAddRatio = self.props.pClickGoldAddRatio + itemnum*paraone  
		unilight.debug("2223" ..  self.props.pClickGoldAddRatio)
		res["data"] = {
			pClickGoldAddRatio = self.props.pClickGoldAddRatio			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_WorldGoldAddRatio) then
		self.props.pWorldGoldAddRatio = self.props.pWorldGoldAddRatio + itemnum*paraone  
		res["data"] = {
			pWorldGoldAddRatio = self.props.pWorldGoldAddRatio			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_GoldRainTimeAdd)  then
		self.props.pGoldRainTimeAdd = self.props.pGoldRainTimeAdd + itemnum*paraone  
		res["data"] = {
			 pGoldRainTimeAdd = self.props.pGoldRainTimeAdd			
		}
	elseif itemtype == tonumber(static_const.Static_ItemType_OfflineGoldAddRatio) then
		self.props.pOfflineGoldAddRatio = self.props.pOfflineGoldAddRatio + itemnum*paraone  
		res["data"] = {
			pOfflineGoldAddRatio = self.props.pOfflineGoldAddRatio			
		}
	end
	--同步下
	unilight.response(userinfo.laccount, res)	
	--发送邮件	
	if mailid ~= 0 then
		userinfo.mailMgr:addNew(mailid, "", "")
	end
	unilight.savefield("userinfo", userinfo.uid, "UserProps", self.props)	
	
end
function UserProps:getUserProp(prop)
	prop = tostring(prop)
	local value = 0
	if prop == tostring(pProtectTimes) then
		value = self.props.pProtectTimes			
	elseif prop == tostring(pPower) then
		value = self.props.pPower
	elseif prop == tostring(pGoldPerSecond)  then
		value = self.props.pGoldPerSecond   
	elseif prop == tostring(pBuildingProduceRate) then
		value = self.props.pBuildingProduceRate  
	elseif prop == tostring(pClickGoldAdd) then
		value = self.props.pClickGoldAdd 
	elseif prop == tostring(pWorldGoldAdd) then
		value = self.props.pWorldGoldAdd   
	elseif prop == tostring(pAutoClickTimes_Time) then
		value = self.props.pAutoClickTimes_Time 
	elseif prop == tostring(pAutoClickTimes_Times) then
		value = self.props.pAutoClickTimes_Times
	elseif prop == tostring(pWeekCardEndTime) then
		value = self.props.pWeekCardEndTime 		
	elseif prop == tostring(pMonthCardEndTime) then
		value = self.props.pMonthCardEndTime
	elseif prop == tostring(pClothes) then
		value = self.props.pClothes
	elseif prop == tostring(pClickGoldAddRatio) then
		value = self.props.pClickGoldAddRatio   
	elseif prop == tostring(pWorldGoldAddRatio) then
		value = self.props.pWorldGoldAddRatio  
	elseif prop == tostring(pGoldRainTimeAdd)  then
		value = self.props.pGoldRainTimeAdd 
	elseif prop == tostring(pOfflineGoldAddRatio) then
		value = self.props.pOfflineGoldAddRatio 
	end
	if value == nil then
		value = 0
	end
	unilight.debug("获取props:" .. prop)
	unilight.debug("获取value:" .. value)
	return value 
end

--商城类
CreateClass("StoreMgr") 
--获得所有商品ID
StoreMgr = 
{
	goodsmap = {}
}
function StoreMgr:new(o)
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
end

function StoreMgr:init()
	unilight.debug("00000000000000")
	for i, v in pairs(StoreData) do
		table.insert(self.goodsmap, v);
		unilight.debug("111", v.id)
	end
end

function StoreMgr:getAllStoreGoods()
	return self.goodsmap  
end

local MoneyType_Diamond = 1
local MoneyType_Gold = 2

--购买商品
function StoreMgr:buyGoods(laccount, goodsid, storeid)
	local uid = laccount.Id
	local userinfo = UserInfo.GetUserInfoById(uid)
	unilight.debug("1110" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	if userinfo == nil then
	unilight.debug("1110" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
		return false, ERROR_CODE.USER_NOT_EXIST
	end 
	unilight.debug("1111" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)

	local storedata = StoreData[goodsid]
	if not storedata then
		return false, ERROR_CODE.ITEM_NOT_EXIST
	end
	
	unilight.debug("1112" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	if storedata.storeid ~= storeid then
		return false, ERROR_CODE.STORE_ERR
	end
	
	unilight.debug("1113" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	--检测物品是否在item表	
	local items = storedata.sellitems
	local args = string.split(items, '_')
	if #args == 0 then 
		return false,ERROR_CODE.STORE_ITEMS_ERR
	end 
	local itemid = tonumber(args[1])
	local itemnum = tonumber(args[2])
	local itemdata = ItemData[itemid]
	unilight.debug("0001" .. " itemid:" .. itemid .. " itemnum:" .. itemnum )
	if not itemdata then
		return false, ERROR_CODE.ITEM_NOT_EXIST
	end
	unilight.debug("1114" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)

	--检测前置
	local beforeid = storedata.beforeid
	if beforeid ~= 0 then
		local buyitems = userinfo.UserItems:getUserHadBuyGoods()
		if buyitems then
			if UserItems:checkUserHadItem(beforeid) == true then
			
			else
				return false,ERROR_CODE.STORE_ITEM_CANT_BUY	
			end
		else
		
		end
	end
	unilight.debug("1115" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	--检测货币
	local price = storedata.price
	local pargs = string.split(price, '_')	
	if #pargs == 0 then 
		return false,ERROR_CODE.STORE_PRICE_ERR
	end 
	local moneytype = tonumber(pargs[1])	
	local moneynum = tonumber(pargs[2])
	local ret = UserInfo.CheckUserMoney(userinfo,moneytype,moneynum)	
	if ret == false then
		if moneytype == static_const.Static_MoneyType_Diamond then
			return false, ERROR_CODE.STORE_DIAMOND_LACK
		end
		if moneytype == static_const.Static_MoneyType_Gold then
			return false, ERROR_CODE.STORE_GOLD_LACK
		end
	end
	--检测开启状态
	local openflag = storedata.openvalue
	unilight.debug("1116---------------" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid .. " openflag" .. openflag)
	if openf1ag == 0 then
	unilight.debug("1116---------------1" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid .. " openflag" .. openflag)
		return false, ERROR_CODE.STORE_TIME_LOCKED
	end
	if tonumber(storedata.opentime) ~= 0  and tonumber(storedata.endtime) then
		local opentime = ttrutil.TimeByNumberDateGet(tonumber(storedata.opentime))
		local endtime = ttrutil.TimeByNumberDateGet(tonumber(storedata.endtime))
		local curtime = os.time() 
		if not (opentime < curtime and curtime < endtime) then
			unilight.debug("1116---------------2" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid .. " openflag" .. openflag .. " opentime" .. opentime .. " endtime" .. endtime .. " curtime" .. curtime)
			return false,ERROR_CODE.STORE_TIME_LOCKED
		end
	end
	unilight.debug("1117" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	--扣货币
	if storeid == static_const.Static_StoreType_Items or storeid == static_const.Static_StoreType_User then
		ret = UserInfo.CheckUserMoney(moneytype,moneynum)	
		if ret == false then
			if moneytype == static_const.Static_MoneyType_Diamond then
				return false, ERROR_CODE.STORE_DIAMOND_LACK
			end
			if moneytype == static_const.Static_MoneyType_Gold then
				return false, ERROR_CODE.STORE_GOLD_LACK
			end
		end
	end
	unilight.debug("1118" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	--处理购买逻辑	
	if storeid == static_const.Static_StoreType_Gift or storeid == static_const.Static_StoreType_Recharge then
		--走创单流程	
		unilight.debug("1119" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
		local orderinfo = {}
		orderinfo["goodid"] = goodsid
		orderinfo["goodnum"] = 1
		orderinfo["rmb"] = moneynum*100
		orderinfo["extdata"] = 0	
		orderinfo["platplatid"] = 331 
		orderinfo["payplatid"] = 331 
		orderinfo["goodname"] = itemdata.name
		orderinfo["redirecturl"] = ""
		local bOk, desc = rechargemgr.CmdCreatePlatOrderRequest(laccount, orderinfo)
		if bOK == fa1se then
			unilight.error(desc)
			return true, ERROR_CODE.STORE_CREAT_ORDER	
		end
		return true, ERROR_CODE.STORE_WAIT_ORDER	
	elseif storeid == static_const.Static_StoreType_Items or storeid == static_const.Static_StoreType_User then
		UserInfo.SubUserMoney(userinfo,moneytype,moneynum)
		userinfo.UserItems:addUserItems(goodsid)
	end
	
	unilight.debug("1121" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	--发货
	UserItems:useItem(userinfo,tonumber(itemid),tonumber(itemnum))

	return true, ERROR_CODE.SUCCESS
end


StoreMgr:init()
