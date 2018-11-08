--全局配置
--
GlobalConst = {
    Initial_Gold = 15,              --角色初始金币
    Initial_Diamond = 1000000,            --角色初始钻石

    Takt_Time = 1,                  --建筑生产时间间隔
    Add_Intimacy_Point = 1,         --雇佣1次增加的亲密度点数
    Intimacy_MaxPoint = 100,        --亲密度上限
    Intimacy_Plus = 0.04,           --亲密度加成百分比

    Click_CD = 0.1,                 --点击CD
    Click_Factor = 0.02,            --点击系数
    Click_Crit_Prob = 0.02,         --点击暴击概率
    Click_Crit_Multiple = 10,       --点击暴击倍数

    Max_OffLine_Time = 12,         --离线计算收益的最大时间(12小时)
	OffLine_Factor = 0.3333,			--离线收益只有在线收益的0.x倍
    Max_RangeIncome_Time = 24,           --看广告的业务加成累计的最大时间(24小时)

	Max_Adviertisement_Times = 10,       --观看广告的最大次数，超过则变为分享
	OffLine_Doubling_Diamond = 100,		--欢迎回来时，离线奖励直接翻倍所需要的钻石数

    Diamond_Quick_Time = 36,              --1钻石能加速礼包的等待s

    Invitation_Star_Awardse = 10,         --邀请有礼领取奖励星级

	Ranking_shows = 100,         --排行榜排名显示数量

	Travel_Time = 86400,         --旅行团团员雇佣时长（秒）

	Travel_CD = 3600,         --旅行团团员CD时长（秒）

	Travel_CD_Diamond = 20,         --旅行团团员清除CD所需要花费的钻石

	Travel_Catch_Number = 3,         --每日免费抓捕次数上限

	Travel_Catch_COST = {20,20,50,50,100},         --花费钻石抓捕所需要的钻石（最后的数值为上限）
	WatchVideoMinusMinuteCd = 60, --玩家每看一次视频减少对应礼包多少分钟的cd
}
