require("lib/class")
require("servers/udp_client")
local lutl = require("lutl")

local TEST_PORT = 1019
local CLIENT_NUM = 1
local SEND_BUFFER = "hello"
local my_clients = {}

local send_time = lutl.getsystime()
local recv_count = 0
local all_cost_time = 0

for i = 1,CLIENT_NUM do
    my_clients[i] = UdpClient.new()
    my_clients[i]:Connect("127.0.0.1", TEST_PORT, TEST_PORT + i, function(client, session_id, data)
        recv_count = recv_count + 1
        local cost_time = lutl.getsystime() - send_time
        print("client", i, "recv", data, "[", recv_count, "] from server ,cost time", cost_time, "ms")
        all_cost_time = all_cost_time + cost_time
        if recv_count < 1000 then
            client:Send(data)
            send_time = lutl.getsystime()
        else
            print("all_cost_time", all_cost_time)
        end
    end)
    my_clients[i]:Send(SEND_BUFFER.." from "..i)
end

while true do
    for i = 1,CLIENT_NUM do
        my_clients[i]:Run("nowait")
    end
end

for i = 1,CLIENT_NUM do
    my_clients[i]:Close()
end
