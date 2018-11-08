module('TaskMgr', package.seeall)
-- 任务相关 公共代码 

-- 任务状态枚举
ENUM_TASK_STATUS = {
	PROGRESS = 1, -- 任务进行中
	COMPLETE = 2, -- 已完成
	RECIEVED = 3, -- 已领取奖励
}
-- 成就枚举
ENUM_ACH_STATUS = {
	PROGRESS = 1, -- 任务进行中
	COMPLETE = 2, -- 已完成
}

-- 临时任务操作类型枚举
ENUM_TEMP_TYPE = {
	CLN = 0,	-- 清零
	ADD = 1,	-- 增加
	SUB = 2,	-- 减少
}

local AchTaskList = {}

-- 创建任务数据表
function CreatDb(gameId)
	TASK_DB_NAME = tostring(gameId) .. "taskinfo"		-- 数据表名字常量 由指定游戏调用时 再传入其gameid
	unilight.createdb(TASK_DB_NAME, "uid")

	ACH_DB_NAME = tostring(gameId) .. "achinfo"	
	unilight.createdb(ACH_DB_NAME, "uid")
end

-- 任务创建
function UserTaskConstuct(uid)
	-- 遍历任务配置表 找出第一批任务
	local userTasks = {
		uid 			= uid,			-- 玩家id
		taskLists 		= {},			-- 任务数组
		temptaskLists 	= {},			-- 用于缓存临时数据
		time 			= 0,			-- 最后一次更改当前节点的时间
	}
	for i,v in ipairs(TableTask) do
		if v.preId == 0 then 
			local userTask = {
				taskId 		= v.id,            				-- 任务id  	
			 	taskStatus	= ENUM_TASK_STATUS.PROGRESS, 	-- 任务状态   	
			}
			table.insert(userTasks.taskLists, userTask)
		end
	end

	TaskUpdate(userTasks)

	return userTasks
end

-- 成就创建
function UserAchConstuct(uid)
	-- 遍历成就配置表 找出第一批任务
	local userAchs = {
		uid 			= uid,			-- 玩家id
		achLists 		= {},			-- 成就数组
		temptaskLists 	= {},			-- 用于缓存临时数据
		time 			= 0,			-- 最后一次更改当前节点的时间
	}
	for i,v in ipairs(TableAch) do
		if v.teamid == 0 then 
			local taskList = {}
			for m,n in ipairs(TableAch) do
				if n.teamid == v.id then
					local taskInfo = {
						taskId 		= n.taskId,
						taskStatus 	= n.taskStatus,
						goal 		= TableTask[n.taskId].goal,
						rewardInfo 	= TableTask[n.taskId].reward,
					}
					table.insert(taskList, taskInfo)
				end
			end

			local userAch = {
				achId 		= v.id,            				-- 成就id  	
			 	achStatus	= ENUM_TASK_STATUS.PROGRESS, 	-- 成就状态   	
				taskInfo    = taskList[1], 					-- 当前任务
			}
			table.insert(userAchs.achLists, userAch)
		end
	end

	AchUpdate(userAchs)
	return userAchs
end

-- 任务更新
function TaskUpdate(userTasks)
	-- 更新节点时间
	userTasks.time = os.time()
	-- 存档
	unilight.savedata(TASK_DB_NAME, userTasks)
end

-- 成就更新
function AchUpdate(userAchs)
	-- 更新节点时间
	userAchs.time = os.time()
	-- 存档
	unilight.savedata(ACH_DB_NAME, userAchs)
end

-- 获取任务列表
function GetTaskList(uid)
	local taskData = GetTaskInfo(uid)
	local taskLists = {}
	for i,v in ipairs(taskData.taskLists) do
		local taskInfo = {
			taskId 		= v.taskId,
			taskStatus 	= v.taskStatus,
			goal 		= TableTask[v.taskId].goal,
			rewardInfo 	= TableTask[v.taskId].reward,
		}
		table.insert(taskLists, taskInfo)
	end
	return taskLists
end

-- 获取成就列表
function GetAchList(uid)
	local AchData = GetAchInfo(uid)
	local AchLists = {}
	for i,v in ipairs(AchData.AchLists) do
		local achInfo = {
			achId 		= v.achId,
			achStatus 	= v.achStatus,
			goal 		= TableAch[v.achId].goal,
			rewardInfo 	= TableAch[v.achId].reward,
			taskInfo    = v.taskInfo, 
		}
		table.insert(AchLists,achInfo)
	end
	return AchLists
end

-- 获取任务信息(也可用于 玩家 进入游戏时 更新当前任务数据)
function GetTaskInfo(uid)
	-- 从数据库中 获取该玩家数据
	local taskData = unilight.getdata(TASK_DB_NAME, uid)

	-- 如果为空 或者 数据不为当天数据 则新建
	if taskData == nil or IsSameDay(os.time(), taskData.time) == false then
		return UserTaskConstuct(uid)
	end	

	return taskData
end

-- 获取成就信息(也可用于 玩家 进入游戏时 更新当前任务数据)
function GetAchInfo(uid)
	local achData = unilight.getdata(ACH_DB_NAME, uid)
	-- 如果为空 或者 数据不为当天数据 则新建
	if achData == nil then
		return UserAchConstuct(uid)
	end	
	return achData
end

-- 领取任务奖励
function GetTaskReward(uid, taskId)
	local tableTask = TableTask[taskId]

	local userTasks = GetTaskInfo(uid)
	local taskLists = userTasks.taskLists

	-- 查看是否当前存在该任务
	local index = 0
	for i,v in ipairs(taskLists) do
		if v.taskId == taskId then
			index = i
			break
		end
	end
	if index == 0 then 
		unilight.info("玩家 当前不存在该任务：" .. taskId)
		return 2, "玩家 当前不存在该任务"
	end

	-- 该任务 是否处于完成待领阶段
	if taskLists[index].taskStatus	== ENUM_TASK_STATUS.PROGRESS then
		unilight.info("该任务 还未完成 不能领取奖励: " .. taskId)
		return 3, "该任务 还未完成 不能领取奖励"
	elseif taskLists[index].taskStatus	== ENUM_TASK_STATUS.RECIEVED then 
		unilight.info("该任务奖励已经领取了: " .. taskId)
		return 4, "该任务奖励已经领取了"
	end

	-- 成功领取该任务奖励 物品获取			
	for i,v in ipairs(tableTask.reward) do
		BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNbr, taskId, BackpackMgr.ENUM_GOODS_SOURCE_TYPE.GAMETASK, nil, ChessItemsHistory.ENUM_TYPE.TASK, "任务")
	end

	-- 任务置任务状态 
	taskLists[index].taskStatus = ENUM_TASK_STATUS.RECIEVED

	--[[ 检测是否开启下一阶段任务 
	local newTask = CheckNextTask(taskId, taskLists[index])
	if newTask ~= nil then
		taskLists[index] = newTask
	end--]]

	-- 数据更新
	userTasks.taskLists = taskLists
	TaskUpdate(userTasks)
	userInfo.active.value = userInfo.active.value + TableTask[taskId].active_value
	local boxId = 0
	for k,v in pairs(ActiveTable) do
		if v.value <= userInfo.active.value and userInfo.active.box < k and userInfo.active.state == 1 then
			boxId = k
			break
		end
	end

	--local chips = chessuserinfodb.RUserChipsGet(uid)

	return 0, "领取任务奖励成功", TableTask[taskId].reward, userInfo.active_value, boxId
end


-- 领取成就奖励
function GetAchReward(uid, taskId)
	local achId = TableTask1[taskId].teamid
	local userAchs = GetAchInfo(uid)
	local taskInfo = userAchs[achId].taskInfo

	-- 查看是否当前存在该任务
	if taskId ~= taskInfo.taskId then 
		unilight.info("该任务暂时不可领取：" .. taskId)
		return 2, "该任务暂时不可领取"
	end

	-- 该任务 是否处于完成待领阶段
	if taskInfo.taskStatus	== ENUM_TASK_STATUS.PROGRESS then
		unilight.info("该任务 还未完成 不能领取奖励: " .. taskId)
		return 3, "该任务 还未完成 不能领取奖励"
	elseif taskInfo.taskStatus	== ENUM_TASK_STATUS.RECIEVED then 
		unilight.info("该任务奖励已经领取了: " .. taskId)
		return 4, "该任务奖励已经领取了"
	end

	-- 成功领取该任务奖励 物品获取			
	for i,v in ipairs(taskInfo.reward) do
		BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNbr, taskId, BackpackMgr.ENUM_GOODS_SOURCE_TYPE.GAMETASK, nil, ChessItemsHistory.ENUM_TYPE.TASK, "任务")
	end

	-- 任务置任务状态 
	if TableTask1[taskId +1] and TableTask1[taskId +1].teamid == achId then
		userAchs[achId].taskInfo.taskId = n.taskId,
		userAchs[achId].taskInfo.taskStatus = ENUM_TASK_STATUS.PROGRESS
	else
		userAchs[achId].achStatus = ENUM_ACH_STATUS.COMPLETE
	end

	AchUpdate(userAchs)

	return 0, "领取任务奖励成功", userAchs, TableTask1[taskId].reward, userInfo.active.value, userInfo.active.box
end

-- 检测是否有下一阶段任务 如果有 返回下一阶段任务内容
function CheckNextTask(taskId, curTask)
	local tableTask = TableTask[taskId]
	if tableTask.nextId ~= 0 then
		-- 生成一个新的任务 然后返回
		local newTableTask = TableTask[tableTask.nextId]
		local newTask = {
			taskId 		= newTableTask.id,            	-- 任务id
			taskType 	= newTableTask.type,			-- 任务类型 	
		 	taskStatus	= ENUM_TASK_STATUS.PROGRESS, 	-- 任务状态   	
		 	current 	= curTask.current,    			-- 当前节点
		}

		-- 检测新任务来了后 是否还已经超过阈值
		if newTask.current >= newTableTask.goal then
			newTask.taskStatus	= ENUM_TASK_STATUS.COMPLETE
		end
		return newTask
	end
	return nil
end

-- 获取当前任务的最大目标
function GetTaskBestGoal(taskId)
	local tableTask = nil
	local index = 0
	while true do
		tableTask = TableTask[taskId]
		if  tableTask.nextId == 0 then
			return tableTask.goal
		end
		taskId = tableTask.nextId

		-- 过滤出错情况 避免死循环
		index = index + 1
		if index >= 100 then
			unilight.error("当前 任务数据表 有误")
			return 0
		end
	end
end

-- 触发任务 公共接口
-- taskType 用于区分何种任务
-- 如果存在临时任务	则填充第三个参数 具体数据枚举中表述
function TriggerTask(uid, taskType, typer)
	local userTasks = GetTaskInfo(uid)
	local taskLists = userTasks.taskLists

	local curTask = nil
	for i,v in ipairs(taskLists) do
		if v.taskType == taskType then
			curTask = v
			break
		end
	end

	if curTask == nil then
		unilight.error("当前不存在该种任务类型 : " .. taskType)
		return 
	end

	-- 获取当前任务类型的 任务名称
	local taskName = nil
	for i,v in ipairs(TableTask) do
		if v.type == taskType then
			taskName = v.name
			break
		end
	end
	unilight.info("当前触发的任务为：" .. taskName)

	-- 获取当前类任务 最大goal
	local bestGoal = GetTaskBestGoal(curTask.taskId)

	if curTask.current >= bestGoal then
		unilight.info("已经达到该类任务 最大要求了")
		return 
	else
		-- 不存在临时任务
		if typer == nil then
			-- 任务次数加1
			curTask.current = curTask.current + 1
		else
			-- 真实任务中 还有需求 才去 计算临时任务
			local temptaskLists = userTasks.temptaskLists or {}
			local curTemp = temptaskLists[taskName] or 0

			if typer == ENUM_TEMP_TYPE.CLN then 
				curTemp = 0
			elseif typer == ENUM_TEMP_TYPE.ADD then
				curTemp = curTemp + 1
				-- 如果临时数据 大于任务中的数据 则更新过去
				if curTemp > curTask.current then
					curTask.current = curTemp
				end
			elseif typer == ENUM_TEMP_TYPE.SUB then
				curTemp = curTemp - 1 
				if curTemp < 0 then 
					curTemp = 0
				end 
			end

			temptaskLists[taskName] = curTemp

			-- 临时任务的更新 必须在该代码段中（修复bug）
			userTasks.temptaskLists = temptaskLists
		end

		-- 检测 是否达到阈值 
		local tableTask = TableTask[curTask.taskId]
		if curTask.current >= tableTask.goal then 
			curTask.taskStatus	= ENUM_TASK_STATUS.COMPLETE
		end

		-- 任务更新
		userTasks.taskLists = taskLists
		TaskUpdate(userTasks)
	end	
end


--开启活跃宝箱
function OpenActiveBox(uid, boxId)
	if userInfo.active and userInfo.active.box ~= boxId then
		return 1, "宝箱未处于可开启状态"
	elseif userInfo.active and userInfo.active.box == boxId then
		if userInfo.active.state == 1 then
			return 2, "宝箱已开启"
		else
			local reward = ActiveTable[boxId].reward
			userInfo.active.state = 1
			--领取
			return 0, "宝箱成功打开", reward
		end
	end
end


-- 判断两个时间是否在同一天
function IsSameDay(time1, time2)
	temp1 = os.date("*t", time1)
	temp2 = os.date("*t", time2)
	if temp1.year == temp2.year and temp1.month == temp2.month and temp1.day == temp2.day then
		return true
	end
	return false
end

-- 判断两个时间是否在同一月
function IsSameMonth(time1, time2)
	temp1 = os.date("*t", time1)
	temp2 = os.date("*t", time2)
	if temp1.year == temp2.year and temp1.month == temp2.month then
		return true
	end
	return false
end

--每天零点更新任务表状态
function UpdateTaskList()
	local userTasks = GetTaskInfo(uid)
	local taskLists = userTasks.taskLists
	for k,v in pairs(taskLists) do
		taskLists[k].taskStatus == ENUM_TASK_STATUS.PROGRESS
	end
	userTasks.taskLists = taskLists
	TaskUpdate(userTasks)
end
