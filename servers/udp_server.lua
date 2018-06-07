require("lib/class")
require("servers/udp_session")
local lkcp = require("lkcp")
local lutl = require("lutl")
local luv = require("luv")
--local p = require("lib/utils").prettyPrint

UdpServer = class()

function UdpServer:ctor()
    -- [conv][addr.ip][addr.port]session_id
    self._session_ids_map = {}
    -- [session_id]session
    self._sessions_map = {}
    self._session_id_index = 0
end

function UdpServer:Update()
    local current = lutl.getsystime()
    for session_id, session in pairs(self._sessions_map) do
        if session == nil or session:Expired() then
            self._session_ids_map[session._conv][session._addr.ip][session._addr.port] = nil
            self._sessions_map[session_id] = nil
        else
            session:Update(current)
        end
    end
end

function UdpServer:UdpRecv(err, chunk, addr, flags)
    if err then
        print("UdpRecv err:", err)
        return
    end
    if chunk == nil then
        return
    end
    local conv = lkcp.getconv(chunk)
    if conv == nil then
        return
    end
    if self._session_ids_map[conv] == nil then
        self._session_ids_map[conv] = {}
    end
    if self._session_ids_map[conv][addr.ip] == nil then
        self._session_ids_map[conv][addr.ip] = {}
    end
    if self._session_ids_map[conv][addr.ip][addr.port] == nil then
        --p({err=err, chunk=chunk, addr=addr, flags=flags})
        self._session_id_index = self._session_id_index + 1
        self._session_ids_map[conv][addr.ip][addr.port] = self._session_id_index
        self._sessions_map[self._session_id_index] = UdpSession.new(self._session_id_index, conv, addr, self._udp, self, self._recv_callback)
    end
    local session_id = self._session_ids_map[conv][addr.ip][addr.port]
    self._sessions_map[session_id]:Recv(chunk)
end

function UdpServer:Listen(port, recv_callback)
    self._udp = luv.new_udp()
    self._timer = luv.new_timer()
    if self._udp == nil or self._timer == nil then
        self._udp = nil
        self._timer = nil
        return false
    end
    self._recv_callback = recv_callback
    luv.udp_bind(self._udp, "0.0.0.0", port, {reuseaddr=true,})
    luv.udp_recv_start(self._udp, function(err, chunk, addr, flags)
        self:UdpRecv(err, chunk, addr, flags)
    end)

    -- start timer
    luv.timer_start(self._timer, 10, 10, function()
        self:Update()
    end)
end

--[[function UdpServer:OnUdpSessionRecv(session_id, data)
    self._recv_callback(self, session_id, data)
end]]

function UdpServer:Run(mode)
  luv.run(mode)
end

function UdpServer:Send(session_id, data)
    if self._sessions_map[session_id] == nil then
        return false
    end
    self._sessions_map[session_id]:Send(data)
    return true
end

function UdpServer:Close()
    luv.close(self._timer)
    luv.walk(luv.close)
    luv.run()
    luv.loop_close()
end
