Net.CmdReqBuyStoreGoodCmd_CS = function(cmd, laccount)
	local res = { }
	res["do"] = "Cmd.ReqBuyStoreGoodCmd_CS"
	
	local uid = laccount.Id
	local goodsid = cmd["data"].goodsid 
	local storeid = cmd["data"].type
	unilight.debug("0000" .. " uid:" .. uid .. " goodsid:" .. goodsid .. " storeid:".. storeid)
	local ret,retcode = StoreMgr:buyGoods(laccount, goodsid, storeid)
	unilight.debug("0001" .. "retcode:" .. retcode)
	res["data"] = {
		goodsid = goodsid,
		ret = retcode, 
		desc = "购买返回",
	}
	return res
end

Net.CmdReqGetCardDayPrizeCmd_CS = function(cmd, laccount)
	local res = { }
	res["do"] = "Cmd.ReqGetCardDayPrizeCmd_CS"
	
	local uid = laccount.Id
	local goodsid = cmd["data"].goodsid 
	local ret, retcode = StoreMgr:getDayCardPrize(uid, goodsid)
	res["data"] = {
		goodsid = goodsid,
		ret = retcode, 
		desc = "领取每日奖励返回",
	}
	return res
end

Net.CmdReqGetGHadBuyGoodsCmd_C = function(cmd, laccount)
	local res = { }
	res["do"] = "Cmd.SendHadBuyStoreGoodsCmd_S"
	
	local uid = laccount.Id
	local userinfo = UserInfo.GetUserInfoById(uid)
	if userinfo ~= nil then
		local buyitems = userinfo.UserItems:getUserHadBuyGoods()
		res["data"] = {
			stgoods = buyitems,
			desc = "玩家已购买商城物品返回",		
		}
		return res
	end
	res["data"] = {
		desc = "玩家已购买商城物品返回",		
	}
	return res
end

Net.CmdReqGetAllStoreGoodsCmd_C = function(cmd, laccount)
	local res = { }
	res["do"] = "Cmd.SendAllStoreGoodsCmd_S"
	
	local uid = laccount.Id
	local goodsmap = StoreMgr:getAllStoreGoods()
	res["data"] = {
		goodsids = goodsmap,
		ret = retcode, 
		desc = "所有商城物品",
	}
	return res
end
--[[
Net.PmdCreatePlatOrderRequestSdkPmd_C = function(cmd, laccount)
        local res = {}
        res["do"] = "Pmd.CreatePlatOrderReturnSdkPmd_S"
        if cmd.data == nil or cmd.data.goodid == nil then
                res.data = {
                        resultCode = 1,
                        desc = "参数缺少"
                }
                return res
        end

        local rev = cmd.data
        local uid = laccount.Id
        local bOk, desc = chessrechargemgr.CmdCreatePlatOrderRequest(laccount, rev)
        if bOk == false then
                unilight.error(desc)
        end
end
]]--
-- 苹果充值成功查询
Net.PmdRechargeQueryRequestIOSSdkPmd_C = function(cmd, laccount)
        local platData = {
                myaccid = laccount.Id,
                platid = laccount.JsMessage.GetPlatid(),
               -- session = laccount.JsMessage.GetSession(),
		session = cmd.data.openkey,
        }
        cmd.data.data = platData
        cmd.data.roleid = laccount.Id
	cmd.data.extdata = cmd.data.openid
    	local resStr = json.encode(encode_repair(cmd.data))
    	local bok = go.buildProtoFwdServer("*Pmd.RechargeQueryRequestIOSSdkPmd_C", resStr, "LS")
    	if bok == true then
        	unilight.info("支付查询转发sdkserver".. resStr)
    	else
        	unilight.error("支付查询转发失败sdkserver".. resStr)
    	end
end

