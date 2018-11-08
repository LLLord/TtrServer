-- 客户端获得玩家任务详细
Net.CmdGetUserTaskInfo_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.GetUserTaskInfo_S"

    local uid = laccount.Id
    local userInfo = UserInfo.GetUserInfoById(uid)

    if userInfo == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    --每日数据可能需要重置
    userInfo.dailyTask:Reset()

    res["data"] = {
        active = userInfo.dailyTask:GetActivity(),
        daily_task = {},
        achieve_task = {},
        active_info = {},
    }

    userInfo.dailyTask.tasks:ForEach(
        function(taskId, taskInfo)
            local tmp = {
                taskid = taskInfo:GetId(),
                times = taskInfo:GetTimes(),
                status = taskInfo:GetStatus(),
            }
            table.insert(res["data"].daily_task, tmp)
        end
    )

    userInfo.dailyTask.activityReward:ForEach(
        function(id, value)
            local tmp = {
                id = id,
                isRecv = (value == 1),
            }
            table.insert(res["data"].active_info, tmp)
        end
    )

    userInfo.achieveTask.tasks:ForEach(
        function(taskId, taskInfo)
            local tmp = {
                taskid = taskInfo:GetId(),
                times = taskInfo:GetTimes(),
                status = taskInfo:GetStatus(),
            }
            table.insert(res["data"].achieve_task, tmp)
        end
    )

    return res
end

-- 客户端获得领取日常任务奖励
Net.CmdReqGetRewardDailyTask_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.ReqGetRewardDailyTask_S"

    local uid = laccount.Id
    local userInfo = UserInfo.GetUserInfoById(uid)

    if userInfo == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    local taskId = cmd["data"].task_id;

    unilight.debug("领取任务奖励..." .. taskId)

    local taskConf = taskTable[taskId]
    if taskConf == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错, 任务在表格里不存在"
        }
        return res
    end

    local taskInfo = userInfo.dailyTask.tasks:Find(taskId);
    if taskInfo == nil then
        taskInfo = userInfo.achieveTask.tasks:Find(taskId);
        if taskInfo == nil then
            res["data"] = {
                resultCode = 1,
                desc = "数据出错, 任务在玩家身上不存在"
            }
            return res
        end 
    end

    if taskInfo:GetStatus() ~= TaskStatusEnum.Finish then
        res["data"] = {
            resultCode = ERROR_CODE.TASK_NOT_FINISH,
            desc = "任务未完成或奖励已经领取"
        }
        return res
    end

    taskInfo:SetStatus(TaskStatusEnum.Receive)

    userInfo.dailyTask.activity = userInfo.dailyTask.activity + taskConf.activeValue

    local money_table = string.split(taskConf.reward, "_")
    local money_type, money =  money_table[1], money_table[2]
    if money_type == nil or money == nil then
        unilight.error("配置表数据出错.........")
        res["data"] = {
            resultCode = 1,
            desc = "",
        }
        return res 
    end

    UserInfo.AddUserMoney(userInfo, money_type, money)

    res["data"] = {
        resultCode = 0,
        desc = "",
        task_id = taskId,
    }

    return res
end

-- 客户端获得领取日常任务奖励
Net.CmdReqGetActiveReward_C = function(cmd, laccount)
    local res = { }
    res["do"] = "Cmd.ReqGetActiveReward_S"

    local uid = laccount.Id
    local userInfo = UserInfo.GetUserInfoById(uid)

    if userInfo == nil then
        res["data"] = {
            resultCode = 1,
            desc = "数据出错"
        }
        return res
    end

    local id = cmd["data"].id;

    local activitConf = taskActivity[id]
    if activitConf == nil then
        res["data"] = {
            resultCode = 1,
            desc = "参数错误"
        }
        return res
    end

    if userInfo.dailyTask:IsExistActivityReward(id) == false then
        res["data"] = {
            resultCode = 1,
            desc = "数据不存在"
        }
        return res
    end

    if userInfo.dailyTask:IsRecvActivityReward(id) == true then
        res["data"] = {
            resultCode = ERROR_CODE.TASK_REWARD_HAS_RECV,
            desc = "奖励已经领取",
        }
        return res     
    end

    if userInfo.dailyTask:GetActivity() < activitConf.cond then
        res["data"] = {
            resultCode = ERROR_CODE.TASK_ACTIVITY_NOT_ENOUGH,
            desc = "活动值不够,不能领取",
        }
        return res   
    end

    userInfo.dailyTask:SetActivityRewardRecv(id)

    local money_table = string.split(activitConf.reward, "_")
    local money_type, money =  money_table[1], money_table[2]

    if money_type == nil or money == nil then
        unilight.error("配置表数据出错.........")
        res["data"] = {
            resultCode = 1,
            desc = "",
        }
        return res 
    end

    UserInfo.AddUserMoney(userInfo, money_type, money)

    res["data"] = {
        resultCode = 0,
        desc = "",
        id = id,
    }
    return res  
end