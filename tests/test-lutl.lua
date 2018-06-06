local lutl = require("lutl")
return require('lib/tap')(function (test)
    test("lutl getsystime and sleep", function (print, p, expect, uv)
        local begin_time = lutl.getsystime()
        p ("begin time", begin_time)
        local count = 0;
        while true do
            lutl.sleep(1000)
            count = count + 1
            if count >= 10 then
                break
            end
            local current = lutl.getsystime()
            p ("after sleep current", current)
        end
        local end_time = lutl.getsystime()
        p ("finish current", end_time)
        assert(end_time - begin_time >= 10000)
        assert(end_time - begin_time < 11000)
    end)
end)