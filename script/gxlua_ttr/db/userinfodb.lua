module('chessuserinfodb', package.seeall)
-- 玩家登陆
function RUserLoginGet(uid, initChips)
	unilight.debug("RUserLoginGet----1111" .. uid)
	local userInfo = RUserInfoGet(uid)
	if userInfo == nil then
	unilight.debug("RUserLoginGet----1112" .. uid)
		return WUserConstuct(uid, initChips)
	else
		local bUpdate = false

		-- 优先检测是否更新玩家平台相关信息
		UpdateUserPlatInfo(userInfo, bUpdate)

		if userInfo.bank == nil then
			userInfo.bank = {
				chips = 0,
                diamond = 0,
			}
			bUpdate = true
		end

		-- 兼容老玩家 set 字段
		if userInfo.set == nil then
			userInfo.set = {
				music = true,
				sound = true,
				rank  = nil,	-- 默认排行榜开关 为nil 用来标记 第一次进入排行榜 弹框
			}
			bUpdate = true
		end

		-- 兼容老玩家数据 max.roundnum、max.maxmulti 字段
		userInfo.max = userInfo.max or {}
		if userInfo.max.maxmulti == nil then
			userInfo.max.maxmulti = 0
			userInfo.max.roundnum = 0
			bUpdate = true
		end

		-- 兼容老玩家数据 max.maxGiftCoupon  giftCoupon  signature
		if userInfo.max.maxGiftCoupon == nil then
			userInfo.max.maxGiftCoupon = 0
			bUpdate = true
		end
		if userInfo.property.giftCoupon == nil then
			userInfo.property.giftCoupon = 0
			bUpdate = true
		end

		if userInfo.base.signature == nil or userInfo.base.signature == "这家伙很懒，什么都没有留下。" then
			userInfo.base.signature = ""
			bUpdate = true
		end

		if userInfo.recharge == nil or userInfo.recharge.isGot == nil then
			userInfo.recharge = {
				first = nil,		-- 默认为nil 表示从有首充系统开始 并未充值过 赋值为 首充金额（分）
				firstTime = nil,	-- 默认为nil 记录首次充值时间
				isGot = false, 		-- 是否已领取首充奖励
			}
			bUpdate = true
		end

		if userInfo.status.continueDays == nil then
			userInfo.status.continueDays = 1
			bUpdate = true
		end

		-- 有些老平台 老账号中 property不存在bankchips字段 兼容
		if userInfo.property.bankerchips == nil then
			userInfo.property.bankerchips = 0
			bUpdate = true
		end

		if bUpdate == true then
			WUserInfoUpdate(uid, userInfo)
		end
		return userInfo
	end
end

-- 更新玩家平台相关信息
function UpdateUserPlatInfo(userInfo, bUpdate)
	local oldstr = table2json(userInfo)
	bUpdate = true
	local laccount = go.accountmgr.GetAccountById(userInfo.uid)
	local platInfo = {}
	platInfo.nickName = laccount.JsMessage.GetNickname()
	--prinickname又来保存玩家修改过昵称
	if platInfo.nickName ~= "" and userInfo.status.prinickname == nil then
		userInfo.base.nickname = platInfo.nickName
	end

	platInfo.headUrl = laccount.JsMessage.GetFaceurl()

	--将非法的头像置为空字符串
	if userInfo.base.headurl == "/0" then
		userInfo.base.headurl = ""
	end

	--priheadurl用来保存玩家手动修改过头像
	if platInfo.headUrl ~= "" and userInfo.base.oldheadurl ~= platInfo.headUrl and userInfo.status.priheadurl == nil then
		--兼容性调整：有时候从平台获取头像的时候会有"/0"的情况，在这里将头像置为空字符串
		if platInfo.headUrl == "/0" then
			platInfo.headUrl = ""
			if userInfo.base.headurl ~= "/0" then
				platInfo.headUrl = userInfo.base.headurl
			end
		end
		userInfo.base.headurl = platInfo.headUrl
	end
	platInfo.platAccount = laccount.JsMessage.GetPlataccount()
	if platInfo.platAccount ~= "" then
		userInfo.base.plataccount = platInfo.platAccount
	end

	userInfo.base.platid = laccount.JsMessage.GetPlatid()
	userInfo.base.subplatid = laccount.JsMessage.GetSubplatid()

	if laccount.Imei ~= nil and laccount.Imei ~= "" and userInfo.base.imei ~= laccount.Imei then --这里暂时先兼容下,否则还得要求lua跟unilight同时更新
		userInfo.base.imei = laccount.Imei
		userInfo.base.osname = laccount.Osname
	end

	-- 性别获取
	local gender = nil
	if go.version and go.version > "v0.11.38"then
		-- 如果存该函数
		if laccount.GetGender ~= nil then
			local temp = laccount.GetGender()
			if temp ~= nil and temp ~= 0 then
				if temp == 1 then
					gender = "男"
				elseif temp == 2 then
					gender = "女"
				end
			elseif temp == 0 then
				laccount.Info("数据更新 玩家性别获取失败:" .. temp)
			end
		end
		if laccount.GetLoginIp ~= nil then
			userInfo.status.loginip = laccount.GetLoginIpstr()
		end
	end
	if gender ~= nil and userInfo.base.gender ~= gender then
		userInfo.base.gender = gender
		laccount.Info("数据更新 玩家性别更新成功")
 	end
	local newstr = table2json(userInfo)
	if newstr ~= oldstr then
		SaveUserData(userInfo)
		laccount.Info("数据更新 刷新数据库")
		return true
	end
end

function RUserBaseInfoGet(userInfo)
	local userBaseInfo = {
		uid = userInfo.uid,
		headUrl = userInfo.base.headurl,
		nickName = userInfo.base.nickname,
		gender  = userInfo.base.gender,
		platId = userInfo.base.platid,
		subPlatId = userInfo.base.subplatid,
		bankChips = userInfo.bank.chips,
		sumRecharge = sumRecharge,
		roundNum = userInfo.max.roundnum,
		maxMulti = userInfo.max.maxmulti,
		giftCoupon = userInfo.property.giftCoupon,	-- 奖券
		signature = userInfo.base.signature,		-- 个性签名
		charm = userInfo.base.charm,                -- 魅力
		points = userInfo.point.points 				-- 积分
	}

    -- 兼容麻将大厅里面 某些存在金币场／某些大厅不存在金币场 所以chips可能置空
    if userInfo.property.chips ~= nil then
        userBaseInfo.remainder = userInfo.property.chips+userInfo.property.bankerchips
    end

	return userBaseInfo, userInfo
end

---------------------------userinfo----------------------------------
--玩家进入游戏时记录
function WLogUserEnterGame(uid, gameId)
	local userData = RUserInfoGet(uid)
	if userData then
		userData.entergame = userData.entergame or {}
		local log = userData.entergame[gameId] or {
			gameId		= gameId,
			enterCount	= 0,			--进入次数
			lastTime	= nil,			--最近一次进入时间
		}

		log.enterCount = log.enterCount + 1
		log.lastTime = os.time()

		userData.entergame[gameId] = log

        unilight.savefield("userinfo", uid, "entergame", userData.entergame)
        if UserInfo and UserInfo.UpdateUserDataCache then
            UserInfo.UpdateUserDataCache(userData)
        end
		return userData
	else
		return nil
	end
end

--获取玩家进入游戏的记录
function RUserEnterGameLogGet(uid, gameId)
	local userData = RUserInfoGet(uid)
	if userData and userData.entergame then
		return userData.entergame[gameId]
	else
		return nil
	end
end

function RUserInfoGetByPlatidPlataccount(platid, plataccount)

	local filter1 = unilight.eq("base.plataccount", plataccount)
	local filter2 = unilight.eq("base.platid", platid)
	local filtera = unilight.a(filter2, filter1)
	local res = unilight.getByFilter("userinfo", filter1, 1)
	if table.empty(res) == true then
		return nil
	end
	return res[1]
end

function RUserInfoGet(uid)
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) then
		return nil
	end

--[[
    --图片服务器换了域名这里检测更新下
    if string.find(userInfo.base.headurl, "image.mj.ucjoy.com:8888") then
        userInfo.base.headurl = string.gsub(userInfo.base.headurl, "image.mj.ucjoy.com:8888", "image.gamelaoyou.com")
        SaveUserData(userInfo)
    end
]]--
	return userInfo
end

function GetUserOtherInfo(uid)
	local userOtherInfo = unilight.getdata("userotherinfo", uid)
	if userOtherInfo == nil then
        userOtherInfo = {
            uid = uid,
        }
        SaveUserOtherInfo(userOtherInfo)
	end
	return userOtherInfo
end

function SaveUserOtherInfo(userOtherInfo)
    unilight.savedata("userotherinfo", userOtherInfo)
    return userOtherInfo
end

function RUserChipsGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return 0
	end
	if userInfo.property.chips < 0 then
		local chips = userInfo.property.chips
		userInfo.property.chips = 0
		unilight.savedata("userinfo", userInfo)
		unilight.error("玩家出现了负值，Bug" .. chips)
        if UserInfo and UserInfo.UpdateUserDataCache then
            UserInfo.UpdateUserDataCache(userInfo)
        end
	end
	return userInfo.property.chips
end

-- 获取玩家在特定游戏昨日排行榜中的名次(前三名)
function GetRankByGameId(uid, gameId)
    local id = tonumber(os.date("%Y%m%d",(os.time()-24*60*60)))
    local rankInfo = unilight.getdata("coinrankrecordinfo", id)
    if rankInfo ~= nil and table.empty(rankInfo) then
        if rankInfo.rankinfo.gameWinRankList and rankInfo.rankinfo.gameWinRankList[gameId] then
            for i=1,3 do
                if rankInfo.rankinfo.gameWinRankList[gameId][i].uid == uid then
                    return true, i
                end
            end
        end
    end
    return false
end

-- 玩家在昨日排行榜中是否前三名（前三名有入场广播）
function GetRankHornByYestodayRank(userData)
    local uid = userData.uid
    local nickName = userData.base.nickname
    local id = tonumber(os.date("%Y%m%d",(os.time()-24*60*60)))
    local rankInfo = unilight.getdata("coinrankrecordinfo", id)
    if rankInfo ~= nil and table.empty(rankInfo) then
        local rank = nil
        local desc = ""
        if rankInfo.rankinfo.allChipsRankList then
            for i=1,3 do
                if rankInfo.rankinfo.allChipsRankList[i].uid == uid then
                    rank = i
                    desc = nickName.."玩家昨日财富榜第"..i.."名，欢迎您回来！"
                    if rank == 1 then
                        return true, desc
                    end
                    break
                end
            end
        end
        if rankInfo.rankinfo.allRechargeRankList then
            for i=1,3 do
                if rankInfo.rankinfo.allRechargeRankList[i].uid == uid then
                    rank = i
                    desc = nickName.."玩家昨日充值榜第"..i.."名，欢迎您回来！"
                    if rank == 1 then
                        return true, desc
                    end
                    break
                end
            end
        end
        if tonumber(os.date("%w",os.time())) == 1 then
            if rankInfo.rankinfo.weekUserCpRankList then
                for i=1,3 do
                    if rankInfo.rankinfo.weekUserCpRankList[i].uid == uid then
                        rank = i
                        desc = nickName.."玩家上周魅力榜第"..i.."名，欢迎您回来！"
                        if rank == 1 then
                            return true, desc
                        end
                        break
                    end
                end
            end
        end
        if rankInfo.rankinfo.allUserCpRankList then
            for i=1,3 do
                if rankInfo.rankinfo.allUserCpRankList[i].uid == uid then
                    rank = i
                    desc = nickName.."玩家昨日魅力榜第"..i.."名，欢迎您回来！"
                    if rank == 1 then
                        return true, desc
                    end
                    break
                end
            end
        end
        if rankInfo.rankinfo.gameWinRankList then
            local gameName = {
                [167] = "百人牛牛",
                [174] = "新将相和",
                [178] = "四海一家",
            }
            for k,v in pairs(rankInfo.rankinfo.gameWinRankList) do
                if gameName[k] then
                    for i=1,3 do
                        if v[i].uid == uid then
                            rank = i
                            desc = nickName.."玩家昨日"..gameName.."盈利榜第"..i.."名，欢迎您回来！"
                            if rank == 1 then
                                return true, desc
                            end
                            break
                        end
                    end
                end
            end
        end
        if rank ~= nil then
            return true, desc
        end
    end
    return false
end

-- 获取魅力信息
function RCharmsInfoGet(uid)
    local userInfo = unilight.getdata("userinfo", uid)
    if table.empty(userInfo) then
        return nil
    end
    -- 玩家魅力值
    local charm = 0
    -- 玩家礼物和数量
    local charmInfo = {}
    if userInfo.base.charm ~= nil then
        charm = userInfo.base.charm
    end
    if userInfo.charminfo ~= nil and table.empty(userInfo.charminfo) == false then
        for k,v in pairs(userInfo.charminfo) do
            table.insert(charmInfo, {id=k, count=v})
        end
    end
    return charm, charmInfo 
end

function RUserGiftCouponsGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return 0
	end

	return userInfo.property.giftCoupon
end

-- 玩家喇叭获取
function RSuonaGet(uid)
    local userData = RUserDataGet(uid)
    if table.empty(userData) or userData.base.isrobot == 1 then
        return 0
    end
    local save = false
    if userData.vip == nil then
        return 0
    end
    if userData.vip.giftSuona == nil then
        userData.vip.giftSuona = { 
            givetime = 0, -- 赠送时间,用于更新
            givenum = 0,          -- 赠送数量,用于消耗
            vipnum = 0,           -- vip等级对应的喇叭数量 
        }
        save = true
    end
    local giftSuona = userData.vip.giftSuona
    if not chessutil.IsSameDay(os.time(), giftSuona.givetime) then
        save = true
        giftSuona.givenum = giftSuona.vipnum
        giftSuona.givetime= os.time()
        userData.vip.giftSuona = giftSuona
    end
    if save then
        WUserInfoUpdate(userData.uid, userData)
    end
    return giftSuona.givenum 
end

-- 麻将钻石获取
function RUserMahjongDiamondGet(uid, userInfo)
	userInfo = userInfo or RUserInfoGet(uid)
	if userInfo == nil or userInfo.mahjong == nil then
		return 0
	end

	return userInfo.mahjong.diamond
end

-- 麻将房卡获取
function RUserMahjongCardGet(uid)
	local userInfo = RUserInfoGet(uid)
	if userInfo == nil or userInfo.mahjong == nil then
		return 0
	end

	return userInfo.mahjong.card
end

function RUserPlatInfoGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return nil
	end
	local platInfo = {
	--	platAccount = userInfo.base.plataccount,
	--	platId = userInfo.base.platid,
	--	subPlatId = userInfo.base.subplatid,
	}
	return platInfo
end

-- 检测玩家域名
function CheckNickName(userData)
	-- 取域名前13位来作校验
	local url 		= go.getconfigstr("image_server2")
	local check 	= string.sub(url,0,13)

	-- 取玩家headUrl前13位
	local headUrl 	= userData.base.headurl
	local pre 		= string.sub(headUrl,0,13)

	if pre == check then
		-- 前缀一致 代表自己服务器内的url
		return true
	else
		-- 发送请求 更换url
		RequstChangeHeadUrl(userData.uid, headUrl)
		return false
	end
end

-- 随机图像生成
function RandomIcon()
	-- 覆盖掉公共代码里面的头像相关数据
	local zoneType = go.getconfigint("zone_type")
	if zoneType ~= nil and zoneType == 1 then
		return "http://h5.publish.bwgame.com.cn/FishApp/head/" .. math.random(1, 8) .. ".jpg"
	else
        if RobotHeadUrl ~= nil then
            return RobotHeadUrl[math.random(1, table.len(RobotHeadUrl))]
        else
            return "http://img.bwgame.com.cn/img/" .. math.random(1, 350) .. ".jpg"
        end
	end
end

-- 创建新玩家
function WUserConstuct(uid, initChips)
	local laccount = go.accountmgr.GetAccountById(uid)
	local platInfo = {}
	local imei = nil
	local osname = nil
	if laccount ~= nil then
		platInfo.nickName = laccount.JsMessage.GetNickname()
		if platInfo.nickName == "" then
			platInfo.nickName = nil
		end
		platInfo.headUrl = laccount.JsMessage.GetFaceurl()
		if platInfo.headUrl == "" then
			platInfo.headUrl = nil
		end
		-- cc365先使用一般图像
		if laccount.JsMessage.GetPlatid() == 365 then
			platInfo.headUrl = "http://h5.publish.bwgame.com.cn/pic/BT_MALE.bmp"
			if 1 == math.random(1,2) then
				platInfo.headUrl = "http://h5.publish.bwgame.com.cn/pic/BT_FEMALE.bmp"
			end
		end
		platInfo.platAccount = laccount.JsMessage.GetPlataccount()
		if platInfo.platAccount == "" then
			platInfo.platAccount = nil
		end
		platInfo.platId = laccount.JsMessage.GetPlatid()
		platInfo.subPlatId = laccount.JsMessage.GetSubplatid()
		-- 推荐人
		local strExtData = laccount.JsMessage.GetExtdata()
		local t = string.sub(strExtData, 1,1)
		if strExtData ~= "" and js == "{" then
			strExtData= string.gsub(tostring(strExtData),"\\", "")
			strExtData = string.gsub(strExtData,"\"{", "{")
			strExtData = string.gsub(strExtData,"}\"", "}")
			unilight.info("玩家uid" .. uid .. " extdata:" .. strExtData)
			local extData = unilight.getreq(strExtData)
			platInfo.inviter = tonumber(extData.inviter)
		end
		if laccount.Imei ~= nil then --这里暂时先兼容下,否则还得要求lua跟unilight同时更新
			imei = laccount.Imei
			osname = laccount.Osname
		end

		-- 通过laccount 获取到个性签名  需要这么一个接口。。(索取 ----------------  mark  )
		-- platInfo.signature = laccount.JsMessage.GetSignature()
		-- if platInfo.signature == "" then
		-- 	platInfo.signature = nil
		-- end

		-- 性别获取
		if go.version and go.version > "v0.11.38"then
			-- 如果存该函数
			if laccount.GetGender ~= nil then
				local temp = laccount.GetGender()
				if temp ~= nil then
					if temp == 0 then
						laccount.Info("创建玩家 性别获取失败:" .. temp)
					else
						if temp == 1 then
							platInfo.gender = "男"
						elseif temp == 2 then
							platInfo.gender = "女"
						end
						laccount.Info("创建玩家 性别获取成功:" .. temp)
					end
				end
			end
		end
	end
	local curtime = os.time()
	local currentdate = chessutil.FormatDateGet()
	local randomHeadUrl = RandomIcon()
	-- 创建基本表
	local userInfo = {
		uid = uid,
		base = {
			nickname = platInfo.nickName or tostring(uid),
			headurl  = platInfo.headUrl or randomHeadUrl,
			email    = platInfo.email or "123@qq.com",
			passwd   = platInfo.passwd or "123456",
			plataccount = platInfo.platAccount or tostring(uid),
			platid = platInfo.platId or 0,
			subplatid = platInfo.subPlatId or 0,
			gender  = platInfo.gender or "男",
			inviter = platInfo.inviter or 0,
			signature = platInfo.signature or "", --"这家伙很懒，什么都没有留下。",	-- 个性签名
			name 		= nil,						-- 真实姓名
			phonenbr	= nil,						-- 手机
			qq			= nil,						-- qq
			zipcode		= nil,						-- 邮编
			addr		= nil,						-- 住址
			imei		= imei,						-- imei
			osname		= osname,					-- osname
			charm       = 0,						-- 魅力
		},
		status = {
			logintime = currentdate,
			loginip = "8.8.8.8",
            registerip = "8.8.8.8",             -- 新增 注册IP
			logintimestamp = curtime,			-- 存入时间戳 用于筛选
			lastlogintime = currentdate,
			registertime = currentdate,
			registertimestamp = curtime,		-- 存入时间戳 用于筛选
			continueDays = 1,
		},
		property = {
			chips = initChips or 5000,
			betall = 0,
			lotteryall = 0,
			profitall = 0,
			bankerchips = 0,
			playnbr = 0,
			giftCoupon = 0, 	        -- 新增 奖券 （货币）
            giftVoucher = 0,            -- 新增 礼品券
            consumeDiamond = 0,         -- 新增 消耗钻石 
            consumeGiftVoucher = 0,     -- 新增 消耗礼品券 
		},
		point = {
			points = 0,
			betall = 0,
			lotteryall = 0,
			profitall = 0,
			bankerpoints = 0,
			playnbr = 0,
			giftCoupon = 0,
		},
		bank = {
			chips = 0,
            diamond = 0,
		},
		max = {
			maxchips = 5000,
			maxpoint = 5000,
			maxGiftCoupon = 0,
		},
		set = {
			music = true,
			sound = true,
			rank  = nil,
		},
		--推广系统
		-- marketing = {
		-- 	parent = 0, --上级代理UID
		-- 	child = {
		-- 		[1000] = --UID
		-- 		{
		-- 			wait_buy = 0, --等待上分
		-- 			wait_sell = 0, --等待下分
		-- 			all_buy = 0, --累计上分
		-- 			all_sell = 0, --累计下分
		-- 		},
		-- 	},
		-- },
		recharge = {
			first = nil,	-- 默认为nil 表示从有首充系统开始 并未充值过 赋值为 首充金额（分）
			isGot = false, 	-- 是否已领取首充奖励
            all   = nil,    -- 最终记录玩家充值了多少
		},
        -- 新增一个用于后续杂七杂八的需要存到玩家身上 又不知如何归类的
        other = {
        }
	}
	WUserInfoUpdate(uid, userInfo)

	return userInfo
end

function WUserInfoModity(uid, modifyInfo)
	local userInfo = RUserInfoGet(uid)
	userInfo.base.headurl = modifyInfo.headUrl or userInfo.base.headurl
	userInfo.base.nickname = modifyInfo.nickName or userInfo.base.nickname
	userInfo.base.gender = modifyInfo.gender or userInfo.base.gender
	userInfo.base.signature = Sensitive.GetString(modifyInfo.signature) or userInfo.base.signature
	userInfo.base.busermodify = true
	--玩家手动修改头像的标志
	if modifyInfo.headUrl ~= nil and modifyInfo.headUrl ~= "" then
		userInfo.status.priheadurl = 1
	end
	--玩家修改昵称的标志
	if modifyInfo.nickName ~= nil and modifyInfo.nickName ~= "" then
		userInfo.status.prinickname = (userInfo.status.prinickname or 0) + 1
	end
 	WUserInfoUpdate(uid, userInfo)
	return RUserBaseInfoGet(userInfo)
end

-- 玩家信息更新
function WUserInfoUpdate(uid, data)
	if uid == nil then
		return nil
	end
	-- 这里对一些最大值进行赋值
	local userInfo = updateMaxInfo(data)
	unilight.savedata("userinfo", userInfo)

    if UserInfo and UserInfo.UpdateUserDataCache then
        UserInfo.UpdateUserDataCache(userInfo)
    end
end

function updateMaxInfo(data)
	data.max = data.max or {}
	data.max.maxchips = data.max.maxchips or 0
    if data.property.chips ~= nil then
        if data.max.maxchips < data.property.chips then
            data.max.maxchips = data.property.chips
        end
    end
	data.max.maxpoint = data.max.maxpoint or 0
	data.point = data.point or {}
	data.point.points = data.point.points or 0
	if data.max.maxpoint < data.point.points then
		data.max.maxpoint = data.point.points
	end
	data.max.maxmulti = data.max.maxmulti or 0
	data.max.roundnum = data.max.roundnum or 0

	-- 奖券 老数据不存在该字段 需要初始化
	data.max.maxGiftCoupon = data.max.maxGiftCoupon or 0
	return data
end

function WSetChips(uid, chips)
	unilight.savefield("userinfo", uid, "property.chips", chips)
end
-- 修改筹码
-- in, type = 1 表示增加, type = 2 表示减少
-- out, remander = 表示剩余钱数, ok
function WChipsChange(uid, type, chips, desc)
	if chips < 0 then
		chips = 0 - chips
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property
	if property == nil then
		unilight.error("WChipsChange()玩家不存在" .. uid)
		return nil
	end
	if userInfo.property.chips < 0 then
		unilight.error("bug err WChipsChange " ..userInfo.property.chips)
		userInfo.property.chips = 0
	end

	local diff = chips
	if type == 1 then
		property.chips = property.chips + chips
		property.lotteryall = property.lotteryall + chips
	else
		if chips <= property.chips then
			property.chips = property.chips - chips
			property.betall = property.betall + chips
		else
			return property.chips, false
		end
		diff = -diff
	end
	property.profitall = property.lotteryall - property.betall
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, property.chips, diff, desc)

	return property.chips, true
end

-- 修改积分
-- in, type = 1 表示增加, type = 2 表示减少
function WPointsChange(uid, changeType, points)
	if points < 0 then
		points = 0 - points
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local point = userInfo.point
	if changeType == 1 then
		point.points = point.points + points
		point.lotteryall = point.lotteryall + points
	else
		point.points = point.points - points
		point.betall = point.betall + points
	end
	point.profitall = point.lotteryall - point.betall
	userInfo.point = point
	WUserInfoUpdate(uid, userInfo)
	return point.points
end

-- 负分清零
function WNegativePointsClear(uid)
	local userInfo = unilight.getdata("userinfo", uid)
	local point = userInfo.point
	if point.points < 0 then
		point.lotteryall = point.lotteryall - point.points
		point.points = 0
	end
	point.profitall = point.lotteryall - point.betall
	userInfo.point = point
	WUserInfoUpdate(uid, userInfo)
	return point.points
end

-- 修改魅力值
-- in, type = 1 表示增加, type = 2 表示减少
-- giftId 礼品ID num 礼品数量 
function WCharmsChange(uid, changeType, charms, giftId, num, userinfo)
	if charms < 0 then
		charms = 0 - charms
	end
	local userInfo = userinfo or unilight.getdata("userinfo", uid)
	local base = userInfo.base
    local number = charms
	if changeType == 1 then
		base.charm = base.charm + charms
	else
		base.charm = base.charm - charms
        number = -number
	end
	userInfo.base = base
	if giftId ~= nil and num ~= nil then
		userInfo.charminfo = userInfo.charminfo or {}
		userInfo.charminfo[giftId] = (userInfo.charminfo[giftId] or 0) + num
	end
    --周魅力值数据，供排行榜使用
    userInfo.weekCharm = userInfo.weekCharm or {}
    local currentWeek = chessutil.ZeroWeekTimestampGet(os.time())
    local lastWeek = chessutil.ZeroWeekTimestampGet((userInfo.weekCharm.time or 0))
    if currentWeek == lastWeek then
        userInfo.weekCharm.charm = userInfo.weekCharm.charm + number
    else
        userInfo.weekCharm.charm = number
    end
    userInfo.weekCharm.time = os.time()
	WUserInfoUpdate(uid, userInfo)
	return base.charm
end

-- 修改奖券
-- in, type = 1 表示增加, type = 2 表示减少
function WGiftCouponsChange(uid, type, giftCoupons)
	if giftCoupons < 0 then
		giftCoupons = 0 - giftCoupons
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property
	if property == nil then
		unilight.error("WGiftCouponsChange()玩家不存在" .. uid)
		return nil
	end
	if type == 1 then
		property.giftCoupon = property.giftCoupon + giftCoupons
	else
		if giftCoupons <= property.giftCoupon then
			property.giftCoupon = property.giftCoupon - giftCoupons
		else
			return property.giftCoupon, false
		end
	end
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)
	return property.giftCoupon, true
end

-- 修改礼品券
-- type =1 表示增加, type = 2 表示减少
function WGiftVoucherChange(uid, type, giftVoucher)
    if giftVoucher < 0 then
        giftVoucher = 0 - giftVoucher
    end
    local userInfo = unilight.getdata('userinfo', uid)
    if userInfo.property == nil then
        unilight.error("WGiftVoucherChange()玩家不存在"..uid)
        return nil
    end
    --这里兼容一下老数据,礼品券字段
    if userInfo.property.giftVoucher == nil then
        userInfo.property.giftVoucher = 0
    end
    --礼品券总消耗字段
    if userInfo.property.consumeGiftVoucher == nil then
        userInfo.property.consumeGiftVoucher = 0
    end
    if type == 1 then
        userInfo.property.giftVoucher = userInfo.property.giftVoucher + giftVoucher
    else
        if giftVoucher <= userInfo.property.giftVoucher then
            userInfo.property.giftVoucher = userInfo.property.giftVoucher - giftVoucher
            userInfo.property.consumeGiftVoucher = userInfo.property.consumeGiftVoucher + giftVoucher
        else
            return userInfo.property.giftVoucher, false 
        end
    end
    WUserInfoUpdate(uid, userInfo)
    return userInfo.property.giftVoucher, true
end

-- 修改喇叭
-- type =1 表示增加, type = 2 表示减少
function WSuonaChange(uid, type, num, userData)
    if num < 0 then
        num = 0 - num 
    end
    local userData = userData or RUserInfoGet(uid) 
    if userData.vip == nil then
        unilight.error("WSuonaChange() 玩家不存在"..uid)
        return nil, false
    end
    -- 这里兼容一下老数据，喇叭字段
    if userData.vip.giftSuona == nil then
        userData.vip.giftSuona = {
            givetime = 0, --赠送喇叭时间
            givenum = 0,          --赠送喇叭数量
            vipnum = 0,           --vip对应喇叭数量
        }
    end
    local giftSuona = userData.vip.giftSuona
    if not chessutil.IsSameDay(os.time(), giftSuona.givetime) then
        giftSuona.givenum = giftSuona.vipnum
        giftSuona.givetime = os.time()
        userData.vip.giftSuona = giftSuona
    end
    if type == 1 then
        giftSuona.givenum = giftSuona.givenum + num
    else
        if num <= giftSuona.givenum then
            giftSuona.givenum = giftSuona.givenum - num
        else
            return giftSuona.givenum, false
        end
    end
    userData.vip.giftSuona = giftSuona
    WUserInfoUpdate(uid, userData)
    return giftSuona.givenum, true
end

-- 修改麻将钻石（前提是必须存在该麻将信息）
-- in, type = 1 表示增加, type = 2 表示减少
function WMahjongDiamondChange(uid, type, num, desc)
	if num < 0 then
		num = 0 - num
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local mahjong = userInfo.mahjong
	if mahjong == nil then
		unilight.error("WMahjongDiamondChange()玩家不存在" .. uid)
		return
	end
	if mahjong.diamond < 0 then
		unilight.error("bug err WMahjongDiamondChange " ..mahjong.diamond)
		mahjong.diamond = 0
	end

	local diff = num
	if type == 1 then
		mahjong.diamond = mahjong.diamond + num
	else
		if num <= mahjong.diamond then
			mahjong.diamond = mahjong.diamond - num
		else
			return mahjong.diamond, false
		end
		diff = -diff
	end

	userInfo.mahjong = mahjong
	WUserInfoUpdate(uid, userInfo)

	-- 钻石流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 2, mahjong.diamond, diff, desc)

	return mahjong.diamond, true
end

-- 修改麻将房卡（前提是必须存在该麻将信息）
-- in, type = 1 表示增加, type = 2 表示减少
function WMahjongCardChange(uid, type, num, desc)
	if num < 0 then
		num = 0 - num
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local mahjong = userInfo.mahjong
	if mahjong == nil then
		unilight.error("WMahjongCardChange()玩家不存在" .. uid)
		return
	end
	if mahjong.card < 0 then
		unilight.error("bug err WMahjongCardChange " ..mahjong.card)
		mahjong.card = 0
	end
	local diff = num
	if type == 1 then
		mahjong.card = mahjong.card + num
	else
		if num <= mahjong.card then
			mahjong.card = mahjong.card - num
		else
			return mahjong.card, false
		end
		diff = -diff
	end
	userInfo.mahjong = mahjong
	WUserInfoUpdate(uid, userInfo)

	-- 房卡流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 3, mahjong.card, diff, desc)

	return mahjong.card, true
end

-- 修改银行存款（用于直接消耗银行存款 -- 暂时只有送礼）
-- in, type = 1 表示增加, type = 2 表示减少
function WBankChipsChange(uid, type, bankChips)
	if bankChips < 0 then
		bankChips = 0 - bankChips
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local bank = userInfo.bank
	if bank == nil then
		unilight.error("WbankChipsChange()玩家不存在" .. uid)
		return nil
	end
	if type == 1 then
		bank.chips = bank.chips + bankChips
	else
		if bankChips <= bank.chips then
			bank.chips = bank.chips - bankChips
		else
			return bank.chips, false
		end
	end
	userInfo.bank = bank
	WUserInfoUpdate(uid, userInfo)
	return bank.chips, true
end

-- 充值数据库入口
function WChipsRecharge(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end
	userInfo.property.chips = userInfo.property.chips + chips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, chips, "充值", nil, ChessItemsHistory.ENUM_TYPE.REC)

	return userInfo.property.chips
end

-- 兑换出去金币减少入口
function WChipsRedeemBack(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end
	userInfo.property.chips = userInfo.property.chips - chips
	if userInfo.property.chips < 0 then
		unilight.error("bug err WChipsRedeemBack" .. chips .. "   " .. userInfo.property.chips)
		userInfo.property.chips = 0
	end
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, -chips, "金币兑出", nil, ChessItemsHistory.ENUM_TYPE.OUT)

	return userInfo.property.chips
end

-- GM设定金币数
function WChipsSet(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end
	userInfo.property.chips = chips
	WUserInfoUpdate(uid, userInfo)
	return userInfo.property.chips
end

-- GM设定麻将钻石
function WMahjongDiamondSet(uid, mahjongDiamond)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil or userInfo.mahjong == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end
	userInfo.mahjong.diamond = mahjongDiamond
	WUserInfoUpdate(uid, userInfo)
	return userInfo.mahjong.diamond
end

-- GM设定麻将房卡
function WMahjongCardSet(uid, mahjongCard)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil or userInfo.mahjong == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end
	userInfo.mahjong.card = mahjongCard
	WUserInfoUpdate(uid, userInfo)
	return userInfo.mahjong.card
end


function UserChipsExchange(srcUid, dstUid, chips)
	local srcUser = unilight.getdata("userinfo", srcUid)
	local dstUser = unilight.getdata("userinfo", dstUid)
	if srcUser == nil or dstUser == nil then
		return false
	end

	if srcUser.property.chips < chips then
		return false
	end

	srcUser.property.chips = serUser.property.chips - chips
	dstUser.property.chips = dstUser.property.chips + chips
	WUserInfoUpdate(srcUid, srcUser)
	WUserInfoUpdate(dstUid, dstUser)

	return srcUser.property.chips
end

-- 加、减上庄金币
function WChangeBankerChips(uid, addChips)
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) or IsRobot(uid) then
		unilight.error("玩家不存在" .. uid)
		return false
	end

	--检查金币数量
	if (addChips > 0 and userInfo.property.chips < addChips) or (addChips < 0 and userInfo.property.bankerchips + addChips < 0) then
		return false
	end

	userInfo.property.chips = userInfo.property.chips - addChips
	userInfo.property.bankerchips = userInfo.property.bankerchips + addChips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	-- ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, -addChips, "加、减上庄金币", nil, ChessItemsHistory.ENUM_TYPE.BANKER)

	return true, userInfo.property.chips, userInfo.property.bankerchips, userInfo
end

-- 将指定玩家金币移入庄家金币库存
function WMoveChipsToBankerChips(uid, bankerChips)
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) or IsRobot(uid) then
		unilight.error("玩家不存在" .. uid)
		return false
	end
	if userInfo.property.chips < bankerChips or bankerChips < 1 then
		return false
	end
	userInfo.property.chips = userInfo.property.chips - bankerChips
	userInfo.property.bankerchips = userInfo.property.bankerchips + bankerChips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	-- ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, -bankerChips, "上庄", nil, ChessItemsHistory.ENUM_TYPE.BANKER)

	return true, userInfo.property.chips, userInfo.property.bankerchips, userInfo
end

-- 将指定玩家庄家金币移入金币库存
function WMoveBankerChipsToChips(uid)
	-- body
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) or IsRobot(uid) then
		unilight.error("玩家不存在" .. uid)
		return false
	end
	if userInfo.property.bankerchips == nil then
		userInfo.property.bankerchips = 0
	end
	userInfo.property.chips = userInfo.property.chips + userInfo.property.bankerchips

	-- 金币流向 全部记录
	-- ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, userInfo.property.bankerchips, "下庄", nil, ChessItemsHistory.ENUM_TYPE.BANKER)

	userInfo.property.bankerchips = 0
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录

	return true, userInfo.property.chips, 0, userInfo
end

function WUpdateBankerChips(uid, oriBankerChips, addProfit)
	-- body
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) then
		unilight.error("玩家不存在" .. uid)
		return false
	end
	userInfo.property.bankerchips = userInfo.property.bankerchips - oriBankerChips + addProfit
	WUserInfoUpdate(uid, userInfo)
	return true, userInfo.property.chips, userInfo.property.bankerchips, userInfo
end

---------------------------------------------------------------------------------------------------------------------
--银行与携带互转
function WBankchipsExChange(uid, chips, exchangeType)
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) then
		unilight.error("玩家不存在" .. uid)
		return false
	end
	local bank = userInfo.bank.chips
	local remainder = userInfo.property.chips
	local diff = chips
	if exchangeType == 0 then
		-- 银行转入携带
		if bank < chips then
			return false
		end
		userInfo.property.chips = remainder + chips
		userInfo.bank.chips = bank - chips
	else
		-- 携带转入银行
		if remainder < chips then
			return false
		end
		userInfo.property.chips = remainder - chips
		userInfo.bank.chips = bank + chips
		diff = -diff
	end
	bank = userInfo.bank.chips
	remander = userInfo.property.chips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, diff, "保险箱存取", nil, ChessItemsHistory.ENUM_TYPE.BANK)

	return true, remander, bank
end

---------------------------------------------------------------------------------------------------------------------
--排行榜
-- getgoldrank
function RChipsRankGet(num)
	chipsRank = chipsRank or {}
	chipsRank.updateTime = chipsRank.updateTime or 0
	local distance = os.time() - chipsRank.updateTime
	if distance < 60 * 60 then
	   return chipsRank.rank
	end
	unilight.debug("查询整体排行榜")
	nbr = 20
	local orderby = unilight.desc("property.chips")
	local usrgroup = unilight.topdata("userinfo", nbr, orderby, nil)
	if table.empty(usrgroup) then
		return nil
	end
	local res = {}
	for i, v in ipairs(usrgroup) do
		res[i] = {
			nickName = v.base.nickname,
			chips = v.property.chips,
			rank = i,
			uid  = v.uid,
		}
	end
	chipsRank.rank = res
	chipsRank.updateTime = os.time()
	return res
end

-- getrgoldrank by uid
function RUserChipsRankGet(uid)
	userChipsRank = userChipsRank or {}
	userChipsRank[uid] = userChipsRank[uid] or {}
	userChipsRank[uid].updateTime = userChipsRank[uid].updateTime or 0
	local distance = os.time() - userChipsRank[uid].updateTime
	if distance < 60 * 60 then
		return userChipsRank[uid].index
	end

	local orderby = unilight.desc("property.chips")
	local index =  unilight.getindex("userinfo", "uid", uid, orderby)
	index = index + 1
	userChipsRank[uid].updateTime = os.time()
	userChipsRank[uid].index = index
	return index
end

---------------------------------------------------------------------------------------------------------------------
-- 检测过是机器人的缓存一下
CommonCheckRobot = {}
-- 加个判断是否为机器人的接口
function IsRobot(uid, userData)
    if CommonCheckRobot[uid] ~= nil then
        return CommonCheckRobot[uid]
    end

    local isRobot = false
	local begin = TableRobotUserInfo[1].uid
	local ended = begin + #TableRobotUserInfo - 1
	if uid >= begin and uid <= ended then
        isRobot = true
	else
        userData = userData or RUserInfoGet(uid)
        if userData ~= nil and userData.base.isrobot == 1 then
            isRobot = true
        end
	end

    CommonCheckRobot[uid] = isRobot

    return isRobot
end


---------------------------------------------------------------------------------------------------------------------
--用户自定义筹码
function SetCusetomBetchips(gameid, uid, betchips, num, legalchips)
	num = num or 5
	legalchips = legalchips or {100, 200, 500, 1000, 5000, 10000, 25000, 50000, 100000, 200000, 500000, 1000000}
	betchips = betchips or {}

	if #betchips ~= num then
		return false, "必须选择"..num.."个"
	end

	for _, chips in ipairs(betchips) do
		if not table.find(legalchips, chips) then
			return false, "无效的筹码"
		end
	end

	allbetchips = unilight.getfield("userinfo", uid, "set.betchps") or {}
	allbetchips[gameid] = betchips

	unilight.savefield("userinfo", uid, "set.betchps", allbetchips)

	return true, ""
end

function GetCusetomBetchips(gameid, uid, userdata)
	local allbetchips
	if userdata and userdata.set and userdata.set.betchips then
		allbetchips = userdata.set.betchips
	else
		allbetchips = unilight.getfield("userinfo", uid, "set.betchps") or {}
	end
	return allbetchips[gameid]
end

---------------------------------------------------------------------------------------------------------------------
-- http 请求替换headurl
function RequstChangeHeadUrl(uid, headUrl)
	local req = {}
	req["do"] = "ChangeHeadurl_C"
	req["data"] = {
		uid 		= uid,
		srcImage	= headUrl
	}
	local url = go.getconfigstr("image_server")
	if url ~= nil then
		unilight.HttpRequestPost("ReturnChangeHeadUrl", url, req)
	else
		unilight.error("更新头像失败 image_server url为nil")
	end
end

Http.ReturnChangeHeadUrl = function (cmd,laccount)
	if cmd.data ~= nil and cmd.data.resultCode == 0 and cmd.data.dstImage ~= nil then
		local uid = cmd.data.uid
		local userData = unilight.getdata("userinfo", uid)
		if userData == nil then
			unilight.error("当前玩家不存在 修改headUrl失败：" .. uid)
			return
		end
		userData.base.oldheadurl 	= userData.base.headurl -- 老头像 非本服务器的headurl保留起来
		userData.base.headurl 		= cmd.data.dstImage
		WUserInfoUpdate(uid, userData)

		local laccount = go.accountmgr.GetAccountById(uid)
		if laccount ~= nil then
			-- 替换头像成功后 重新给前端刷新一下头像数据
			local userBaseInfo = chessuserinfodb.RUserBaseInfoGet(userData)
			local brdInfo = {}
			brdInfo["do"] = "Cmd.UserBaseInfoReturnLbyCmd_S"
			brdInfo["data"] = {
				resultCode 	= 0,
				desc 		= "ok",
				uid 		= uid,
				userInfo 	= userBaseInfo,
			}
			unilight.success(laccount, brdInfo)
			unilight.info("新玩家头像存储到本地服务器后 返回最新头像数据 headUrl:" .. userBaseInfo.headUrl)
		end
	end
end
---------------------------------------------------------------------------------------------------------------------
--

-- gm查询玩家推荐排行榜相关数据
function GetRecommendStatisticsByGm(uid, nickName, curPage, perPage)
    local filter = nil

    if uid ~= nil and uid ~= 0 then
        filter = unilight.eq("uid", uid)
    else
        if nickName ~= nil and nickName ~= "" then
            filter = unilight.eq("base.nickname", nickName)
        end
    end

    local infoNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
    local maxPage = math.ceil(infoNum/perPage)

	if curPage > maxPage then
		return 1, "页数超过上限 curPage:" .. curPage .. "	maxPage:" .. maxPage
	end

    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(unilight.desc("marketing.childnum")).Skip((curPage-1)*perPage).Limit(perPage))

    local recommendData = {}

	for i,userInfo in ipairs(info) do
        local data = {
            recommendedid = userInfo.uid,
            recommendedname = userInfo.base.nickname,
            playernumber = userInfo.marketing.childnum or 0,
            gamenumber = userInfo.marketing.childplaynum or 0,
            toprecommendedid = userInfo.marketing.parent or 0,
            toprecommendedname = userInfo.marketing.parentnickname or "",
        }

		table.insert(recommendData, data)
    end

	return 0, "获取推荐数据成功", maxPage, recommendData
end

---王海军添加,希望升级成所有跟db相关的操作都叫Data而不叫Info
RUserBaseDataGet = RUserBaseInfoGet
RUserDataGet = RUserInfoGet
RUserPlatDataGet = RUserPlatInfoGet
WUserDataModity = WUserInfoModity
WUserDataUpdate = WUserInfoUpdate
updateMaxData = updateMaxInfo

GetUserDataBaseInfo = RUserBaseDataGet
CreateUserData = WUserConstuct
GetUserDataById = RUserInfoGet
GetLoginUserDataById = RUserLoginGet
SaveUserDataById = WUserInfoUpdate
GetUserPlatDataById = RUserPlatInfoGet
SaveUserBaseData = WUserInfoModity
UpdateMaxData = updateMaxInfo
function SaveUserData(userdata)
	SaveUserDataById(userdata.uid,userdata)
end
