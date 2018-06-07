require("lib/class")
local lkcp = require("lkcp")
local lutl = require("lutl")
local luv = require("luv")

local UDP_SESSION_EXPIRED_TIMEOUT = 30 * 1000

UdpSession = class()

function UdpSession:UdpSend(data)
    luv.udp_try_send(self._udp, data, self._addr.ip, self._addr.port)
end

function UdpSession:Alive()
    self._session_expired_time = lutl.getsystime() + UDP_SESSION_EXPIRED_TIMEOUT
end

function UdpSession:ctor(session_id, conv, addr, udp, parent, recv_callback)
    self._session_id = session_id
    self._conv = conv
    self._addr = addr
    self._udp = udp
    self._parent = parent
    self._recv_callback = recv_callback
    self._session_expired_time = 0
    self._time_to_update = 0
    self._kcp = lkcp.create(self._conv, self, function(session, data)
        session:UdpSend(data)
    end)
    assert(self._kcp ~= nil)
    if self._kcp ~= nil then
        self._kcp:nodelay(1, 10, 2, 1)
        self._kcp:wndsize(128, 128)
        self._session_expired_time = lutl.getsystime() + UDP_SESSION_EXPIRED_TIMEOUT
    end
end

--[[function UdpSession:Destroy()
    if self._kcp ~= nil then
        self._kcp:release()
    end
end]]

function UdpSession:Update(current, force_update)
    if force_update or current >= self._time_to_update then
        self._kcp:update(current)
        self._time_to_update = self._kcp:check(current)
    end

    if force_update then
        self._kcp:flush()
    end

    local alive = false
    while true do
        data = self._kcp:recv()
        if data == nil or data == "" then
            break
        end
        self._recv_callback(self._parent, self._session_id, data)
        alive = true
    end
    if alive then
        self:Alive()
    end
end

function UdpSession:Recv(data)
    if self._kcp:input(data) >= 0 then
        self:Update(lutl.getsystime(), true)
    end
end

function UdpSession:Send(data)
    if self._kcp:send(data) >= 0 then
        self:Update(lutl.getsystime(), true)
    end
end

function UdpSession:Expired()
    return lutl.getsystime() >= self._session_expired_time
end
