-- FILE: map.xlsx SHEET: 建筑 KEY: Id
TableBuilding = {
[1]={["Id"]=1,["mapid"]=101,["OpenCost"]="2_0"},
[2]={["Id"]=2,["mapid"]=101,["OpenCost"]="2_0"},
[3]={["Id"]=3,["mapid"]=101,["OpenCost"]="2_0"},
[4]={["Id"]=4,["mapid"]=101,["OpenCost"]="2_0"},
[5]={["Id"]=5,["mapid"]=102,["OpenCost"]="2_3000000"},
[6]={["Id"]=6,["mapid"]=102,["OpenCost"]="2_3000000"},
[7]={["Id"]=7,["mapid"]=102,["OpenCost"]="2_3000000"},
[8]={["Id"]=8,["mapid"]=102,["OpenCost"]="2_3000000"},
[9]={["Id"]=9,["mapid"]=103,["OpenCost"]="2_7500000000"},
[10]={["Id"]=10,["mapid"]=103,["OpenCost"]="2_7500000000"},
[11]={["Id"]=11,["mapid"]=103,["OpenCost"]="2_7500000000"},
[12]={["Id"]=12,["mapid"]=103,["OpenCost"]="2_7500000000"},
[13]={["Id"]=13,["mapid"]=104,["OpenCost"]="1_300"},
[14]={["Id"]=14,["mapid"]=104,["OpenCost"]="1_300"},
[15]={["Id"]=15,["mapid"]=104,["OpenCost"]="1_300"},
[16]={["Id"]=16,["mapid"]=104,["OpenCost"]="1_300"},
[17]={["Id"]=17,["mapid"]=105,["OpenCost"]="1_500"},
[18]={["Id"]=18,["mapid"]=105,["OpenCost"]="1_500"},
[19]={["Id"]=19,["mapid"]=105,["OpenCost"]="1_500"},
[20]={["Id"]=20,["mapid"]=105,["OpenCost"]="1_500"},
[21]={["Id"]=21,["mapid"]=106,["OpenCost"]="1_800"},
[22]={["Id"]=22,["mapid"]=106,["OpenCost"]="1_800"},
[23]={["Id"]=23,["mapid"]=106,["OpenCost"]="1_800"},
[24]={["Id"]=24,["mapid"]=106,["OpenCost"]="1_800"},
[25]={["Id"]=25,["mapid"]=107,["OpenCost"]="1_1100"},
[26]={["Id"]=26,["mapid"]=107,["OpenCost"]="1_1100"},
[27]={["Id"]=27,["mapid"]=107,["OpenCost"]="1_1100"},
[28]={["Id"]=28,["mapid"]=107,["OpenCost"]="1_1100"},
[29]={["Id"]=29,["mapid"]=108,["OpenCost"]="1_1300"},
[30]={["Id"]=30,["mapid"]=108,["OpenCost"]="1_1300"},
[31]={["Id"]=31,["mapid"]=108,["OpenCost"]="1_1300"},
[32]={["Id"]=32,["mapid"]=108,["OpenCost"]="1_1300"},
}
setmetatable(TableBuilding, {__index = function(__t, __k) if __k == "query" then return function(Id) return __t[Id] end end end})
