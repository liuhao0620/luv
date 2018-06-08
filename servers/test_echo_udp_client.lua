require("lib/class")
require("servers/udp_client")
local lutl = require("lutl")
local p = require("lib/utils").prettyPrint

local TEST_PORT = 1019
local CLIENT_NUM = 1
local SEND_BUFFER = "hello"
local SEND_INTERVAL = 200
local SEND_NUM = 1000
local my_clients = {}

local send_time = {}
local recv_count = {}
local all_cost_time = {}
local max_cost_time = {}
local min_cost_time = {}
local cost_times = {}

for i = 1,CLIENT_NUM do
    my_clients[i] = UdpClient.new()
    my_clients[i]:Connect("120.27.11.202"--[["127.0.0.1"]], TEST_PORT, TEST_PORT + i, function(client, session_id, data)
        recv_count[i] = recv_count[i] + 1
        local cost_time = lutl.getsystime() - send_time[i]
        print("client", i, "recv", data, "[", recv_count[i], "] from server ,cost time", cost_time, "ms")
        all_cost_time[i] = all_cost_time[i] + cost_time
        if cost_time > max_cost_time[i] then
            max_cost_time[i] = cost_time
        end
        if cost_time < min_cost_time[i] then
            min_cost_time[i] = cost_time
        end
        cost_times[i][recv_count[i]] = cost_time
    end)
    send_time[i] = lutl.getsystime()
    recv_count[i] = 0
    all_cost_time[i] = 0
    max_cost_time[i] = 0
    min_cost_time[i] = 1000
    cost_times[i] = {}
end

while true do
    for i = 1,CLIENT_NUM do
        if lutl.getsystime() > send_time[i] + SEND_INTERVAL and recv_count[i] < SEND_NUM then
            my_clients[i]:Send(SEND_BUFFER.." from "..i)
            send_time[i] = lutl.getsystime()
        elseif recv_count[i] == SEND_NUM then
            recv_count[i] = recv_count[i] + 1
            p("client", i, cost_times[i])
            print("client", i, "all_cost_time", all_cost_time[i], "min_cost_time", min_cost_time[i], "max_cost_time", max_cost_time[i])
        end
        my_clients[i]:Run("nowait")
    end
end

for i = 1,CLIENT_NUM do
    my_clients[i]:Close()
end
