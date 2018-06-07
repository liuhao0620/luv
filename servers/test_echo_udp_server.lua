require("lib/class")
require("servers/udp_server")
local lkcp = require("lkcp")
local lutl = require("lutl")
local luv = require("luv")

local TEST_PORT = 1019

local my_server = UdpServer.new()
my_server:Listen(TEST_PORT, function(server, session_id, data)
    print("recv", data, "from", session_id)
    server:Send(session_id, data)
end)
my_server:Run()
my_server:Close()
