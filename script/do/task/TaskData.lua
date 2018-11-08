TaskConditionEnum = 
{
	LoginEvent = 0,						--登录
	BuildingLevelupEvent = 1,			--升级建筑
	BuildingChangeEvent = 2,			--建筑改造
	TravelLevelupEvent = 3,				--旅行团等级提升
	OpenMapEvent = 4,					--开启地图
	ClickEvent = 5,						--点击次数事件
	EmployFriendEvent = 6,				--雇佣好友事件
	CaptureFriendEvent = 7,				--抓捕好友事件
	StopCaptureEvent = 8,				--防御抓捕
	CostDiamondEvent  = 9,				--累积消耗砖石
	ApplyFriendEvent = 10,				--申请好友
	AskFriendEvent = 11,				--邀请好友玩游戏
	SharedGameEvent = 12,				--分享好友
}

TaskStatusEnum =
{
	Begin = 2,							--所有的任务都是自动开启，也没有开启任务的条件
	Finish = 1,							--任务已完成，但未领取奖励
	Receive = 3,							--奖励已领取
}

CreateClass("TaskData")

function TaskData:init(id, event, times, status)
	self.id = id
	self.times = times
	self.status = status
	self.event = event
end

function TaskData:SetDBTable(data)
	self.id = data.id or self.id
	self.times = data.times or self.times
	self.status = data.status or self.status
	self.event = data.event or self.event
end

function TaskData:GetDBTable()
	local data = {}
	data.id = self.id
	data.times = self.times
	data.status = self.status
	data.event = self.event
	return data
end

function  TaskData:GetId()
	return self.id
end

function TaskData:GetTimes()
	return self.times
end

function TaskData:GetEvent()
	return self.event
end

function TaskData:GetStatus()
	return self.status
end

function TaskData:SetStatus(status)
	self.status = status
end

function TaskData:AddTimes(times)
	if times <= 0 then
		times = 0
	end
	self.times = self.times + times
end
