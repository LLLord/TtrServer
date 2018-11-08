-- FILE: rangeincome.xlsx SHEET: 随机宝箱 KEY: id
TreasureBoxData = {
[1]={["id"]=1,["mintime"]=60,["maxtime"]=120,["probability"]=0.0,["time"]=30,["duration"]=30,["multiple"]=2},
[2]={["id"]=2,["mintime"]=180,["maxtime"]=300,["probability"]=0.1,["time"]=45,["duration"]=30,["multiple"]=2},
[3]={["id"]=3,["mintime"]=360,["maxtime"]=600,["probability"]=0.2,["time"]=60,["duration"]=30,["multiple"]=2},
[4]={["id"]=4,["mintime"]=900,["maxtime"]=1800,["probability"]=0.3,["time"]=110,["duration"]=30,["multiple"]=2},
[5]={["id"]=5,["mintime"]=2700,["maxtime"]=3600,["probability"]=0.4,["time"]=270,["duration"]=30,["multiple"]=2},
[6]={["id"]=6,["mintime"]=5400,["maxtime"]=7200,["probability"]=0.5,["time"]=450,["duration"]=30,["multiple"]=2},
[7]={["id"]=7,["mintime"]=9000,["maxtime"]=18000,["probability"]=0.5,["time"]=640,["duration"]=30,["multiple"]=2},
}
setmetatable(TreasureBoxData, {__index = function(__t, __k) if __k == "query" then return function(id) return __t[id] end end end})
