-- FILE: welfare.xlsx SHEET: 登录 KEY: id
DailyLoginTable = {
[1]={["id"]=1,["reward"]="1_50"},
[2]={["id"]=2,["reward"]="1_100"},
[3]={["id"]=3,["reward"]="1_100"},
[4]={["id"]=4,["reward"]="1_100"},
[5]={["id"]=5,["reward"]="1_150"},
[6]={["id"]=6,["reward"]="1_150"},
[7]={["id"]=7,["reward"]="1_250"},
}
setmetatable(DailyLoginTable, {__index = function(__t, __k) if __k == "query" then return function(id) return __t[id] end end end})
