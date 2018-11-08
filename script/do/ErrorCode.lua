ERROR_CODE = {
	--Common
	SUCCESS = 0,
	ARGUMENT_ERROR = 1,							--参数格式错误
	LOGICAL_ERROR = 2,							--逻辑错误
	TABLE_ERROR = 3,							--表中数据有错
	MONEY_NOT_ENOUGH = 4,						--金币不足
	DIAMOND_NOT_ENOUGH = 5,						--钻石不足
	OPEATE_AGAIN = 6,							--不能重复操作
	ID_NOT_FOUND = 7,							--找不到相应的ID

	--Building
	BUILDING_REBUILD_MAX = 10001,					--建筑物已达到最大改造等级
	BUILDING_LEVEL_MAX = 10002,						--建筑物已达到最大等级
	BUILDING_BUY_AGAIN = 10003,						--建筑物重复购买
	BUILDING_NOT_BUY = 10004,						--建筑尚未购买
	BUILDING_LEVEL_NOT_ENOUGH = 10005,				--建筑等级不足
	BUILDING_STATE_NOT_OPEN = 10006,				--该地图尚未开启

	--friends
	FRIENDS_MAX_LIMIT = 10100,						--好友数量已达上限
	FRIENDS_IS_YOUR_FRIEND = 10101,					--对方已是你的好友
	FRIENDS_CAN_ADD_SELF = 10102,					--不能加自己为好友
	FRIENDS_APPLY_TOO_MUCH = 10103,					--已经申请
	TRAVEL_NO_POS = 10104,							--没有更多位置了，需解锁新位置
	TRAVEL_CANNOT_EMPLY_TWICE = 10105,				--已经被你雇佣过了
	TRAVEL_IN_EMPLOY_CD = 10106,					--雇佣CD时间，暂时不能被你雇佣
	TRAVEL_LEVEL_LIMIT = 10107,						--该好友等级高过你，不能雇佣（抓捕）
	TRAVEL_STAR_NOT_ENOUGH = 10108,					--星级不够
	TRAVEL_POS_LIMIT = 10109,						--已经达到最大值，解锁失败
	TRAVEL_LEVEL_NOT_ENOUGH = 10110,				--抱歉，团长等级不够，不能解锁
	TRAVEL_NEED_BUY_HEAD = 10111,					--这个头像需要先购买

	--task
	TASK_REWARD_HAS_RECV = 10200,					--奖励已经领取
	TASK_ACTIVITY_NOT_ENOUGH = 10201,				--活动值不够,不能领取
	TASK_NOT_FINISH = 10203,						--任务未完成或奖励已经领取

	--Store	
	USER_NOT_EXIST = 20001,
	ITEM_NOT_EXIST = 20002,
	STORE_ERR = 20003,
	STORE_ITEMS_ERR	= 20004,
	STORE_ITEM_CANT_BUY = 20005,
	STORE_PRICE_ERR	= 20006,
	STORE_DIAMOND_LACK = 20007,
	STORE_GOLD_LACK = 20008,
	STORE_TIME_LOCKED = 20009,
	STORE_CREAT_ORDER = 20010,
	STORE_WAIT_ORDER = 20011,


}
