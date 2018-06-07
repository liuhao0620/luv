require("lib/class")
require("servers/udp_session")
local lkcp = require("lkcp")
local lutl = require("lutl")
local luv = require("luv")

UdpClient = class()

function UdpClient:ctor()
end

function UdpClient:Update()
    local current = lutl.getsystime()
    self._session:Update(current)
end

function UdpClient:UdpRecv(err, chunk, addr, flags)
    if err then
        print("UdpRecv err:", err)
        return
    end
    if chunk == nil then
        return
    end
    local conv = lkcp.getconv(chunk)
    if conv == nil or conv ~= self._conv then
        return
    end
    if addr.ip ~= self._addr.ip or addr.port ~= self._addr.port then
        return
    end
    self._session:Recv(chunk)
end

function UdpClient:Connect(server_ip, server_port, port, recv_callback)
    self._udp = luv.new_udp()
    self._timer = luv.new_timer()
    if self._udp == nil or self._timer == nil then
        self._udp = nil
        self._timer = nil
        return false
    end
    self._addr = {}
    self._addr.ip = server_ip
    self._addr.port = server_port
    self._recv_callback = recv_callback
    luv.udp_bind(self._udp, "0.0.0.0", port, {reuseaddr=true,})
    luv.udp_recv_start(self._udp, function(err, chunk, addr, flags)
        self:UdpRecv(err, chunk, addr, flags)
    end)

    self._conv = math.floor(math.random() * 65536 * 65536)
    self._session = UdpSession.new(1, self._conv, self._addr, self._udp, self, self._recv_callback)

    -- start timer
    luv.timer_start(self._timer, 10, 10, function()
        self:Update()
    end)
end

function UdpClient:Run(mode)
  luv.run(mode)
end

function UdpClient:Send(data)
    if data == nil or data == "" then
        return false
    end
    self._session:Send(data)
    return true
end

function UdpClient:Close()
    luv.close(self._timer)
    luv.walk(luv.close)
    luv.run()
    luv.loop_close()
end
