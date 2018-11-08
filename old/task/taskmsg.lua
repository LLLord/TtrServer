
-- 获取任务列表
Net.CmdGetTaskListTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetTaskListTaskCmd_S"

	local uid = laccount.Id
	local userTasks = TaskMgr.GetTaskList(uid)
	local userAchs = TaskMgr.GetAchList(uid)

	res["data"] = {
		resultCode = 0,
		desc = "获取任务列表成功",
		taskInfo = userTasks,
		achInfo = userAchs,
	}
	return res
end

-- 领取指定任务奖励
Net.CmdGetTaskRewardTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetTaskRewardTaskCmd_S"
	if cmd.data == nil or cmd.data.taskId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local taskId = cmd.data.taskId
	local taskType = cmd.data.taskType
	local uid = laccount.Id

	if taskType == 0 then
		local ret, desc, reward, activeValue, activeBox = TaskMgr.GetTaskReward(uid, taskId)
		res["data"] = {
			resultCode = ret,
			desc = desc,
			achInfo = {},
			remainder = remainder, 
			reward = reward,
			activeValue = activeValue,
			activeBox = activeBox,
		}
	elseif taskType == 1 then
		local ret, desc, achInfo, reward, activeValue, activeBox = TaskMgr.GetAchReward(uid, taskId)
			res["data"] = {
			resultCode = ret,
			desc = desc,
			achInfo = {},
			remainder = remainder, 
			reward = reward,
			activeValue = activeValue,
			activeBox = activeBox,
		}
	end
	return res
end

-- 开启活跃宝箱
Net.CmdOpenActiveBoxCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.OpenActiveBoxCmd_S"

	local uid = laccount.Id
	if cmd.data == nil or cmd.data.boxId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end

	local ret, desc, reward = TaskMgr.OpenActiveBox(uid, cmd.data.boxId)
	res["data"] = {
		resultCode = ret,
		desc = desc,
		reward = reward,
	}
	return res
end