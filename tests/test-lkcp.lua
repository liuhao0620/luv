local lkcp = require("lkcp")
local lutl = require("lutl")

local LkcpTestImpl = function(mode, p)
    local kNetworkSimulator = {
        lostrate = 0,
        rttmin = 0,
        rttmax = 0,
        [1] = {
            buffs = {},
            push_index = 1,
        },
        [2] = {
            buffs = {},
            push_index = 1,
        },
    }
    
    function SimulatorInit(lostrate, rttmin, rttmax)
        kNetworkSimulator.lostrate = lostrate
        kNetworkSimulator.rttmin = rttmin
        kNetworkSimulator.rttmax = rttmax
    end
    
    function SimulatorSend(index, chunk)
        if math.random() < kNetworkSimulator.lostrate then
            return
        end
        local buff = {}
        buff.data = chunk
        buff.use_time = lutl.getsystime() + kNetworkSimulator.rttmin + (kNetworkSimulator.rttmax - kNetworkSimulator.rttmin) * math.random()
        table.insert(kNetworkSimulator[index].buffs, buff)
    end
    
    function SimulatorRecv(index)
        local current = lutl.getsystime()
        for idx,buff in pairs(kNetworkSimulator[index].buffs) do
            if buff ~= nil and buff.use_time >= current then
                local chunk = buff.data
                kNetworkSimulator[index].buffs[idx] = nil
                return chunk
            end
        end
        return nil
    end
    
    local KcpSend = function(user, chunk)
        if user == 1 then
            -- send to 2
            SimulatorSend(2, chunk)
        end
        if user == 2 then
            -- send to 1
            SimulatorSend(1, chunk)
        end
    end

    SimulatorInit(0.2, 15, 99)
    math.randomseed(lutl.getsystime())

    local kcp1 = lkcp.create(0x11223344, 1, KcpSend)
    local kcp2 = lkcp.create(0x11223344, 2, KcpSend)
    
    kcp1:wndsize(128, 128)
    kcp2:wndsize(128, 128)
    
	if mode == 0 then
        -- normal mode
		kcp1:nodelay(0, 10, 0, 0)
		kcp2:nodelay(0, 10, 0, 0)
	elseif mode == 1 then
		-- normal mode without flow control
		kcp1:nodelay(0, 10, 0, 1)
		kcp2:nodelay(0, 10, 0, 1)
	else
		-- fast mode
		kcp1:nodelay(1, 10, 2, 1)
		kcp2:nodelay(1, 10, 2, 1)
		kcp1:setminrto(10)
		--kcp1->fastresend = 1;
    end
    kcp1:nodelay(1, 10, 1, 1)
    kcp2:nodelay(1, 10, 1, 1)
    kcp1:setminrto(10)
    kcp2:setminrto(10)
    
    local next_send_time = lutl.getsystime() + 20
    local recv_count = 0
    local send_index = 0
    
    local costtimes = {}
    
    local test_begin = lutl.getsystime()
    while true do
        lutl.sleep(1)
        local current = lutl.getsystime();
        kcp1:update(current)
        kcp2:update(current)

        while current >= next_send_time do
            send_index = send_index + 1
            local send_data = tostring(send_index)
            kcp1:send(send_data)
            costtimes[send_index] = {}
            costtimes[send_index].send_time = lutl.getsystime()
            next_send_time = next_send_time + 20
        end

        -- try to recv from kcp2
        while true do
            local data = SimulatorRecv(1)
            if data ~= nil then
                kcp1:input(data)
            else
                break
            end
        end

        -- try to recv from kcp1
        while true do
            local data = SimulatorRecv(2)
            if data ~= nil then
                kcp2:input(data)        
            else
                break
            end
        end

        -- send back to kcp1 when kcp2 recv data
        while true do
            local data = kcp2:recv()
            if data ~= nil then
                kcp2:send(data)
            else
                break
            end
        end

        -- check index when kcp1 recv data
        while true do
            local data = kcp1:recv()
            if data ~= nil then
                recv_count = recv_count + 1
                local data_index = tonumber(data)
                assert(costtimes[data_index] ~= nil)
                assert(recv_count == data_index)
                costtimes[data_index].recv_time = lutl.getsystime()
                costtimes[data_index].cost_time = costtimes[data_index].recv_time - costtimes[data_index].send_time
            else
                break
            end
        end

        if recv_count >= 100 then
            break
        end
    end
    local test_end = lutl.getsystime()
    
    kcp1:release()
    kcp2:release()
    p(costtimes)
    p("send", send_index, "recv", recv_count, "use time", test_end - test_begin)
end

return require('lib/tap')(function (test)
    test("kcp normal mode", function (print, p, expect, uv)
        LkcpTestImpl(0, p)
    end)
    test("kcp normal mode without flow control", function (print, p, expect, uv)
        LkcpTestImpl(1, p)
    end)
    test("kcp fast mode", function (print, p, expect, uv)
        LkcpTestImpl(2, p)
    end)
end)