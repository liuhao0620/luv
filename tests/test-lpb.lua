local lpb = require("pb")
local lpbio = require("pb.io")
local lpbconv = require("pb.conv")
local lpbbuffer = require("pb.buffer")
local lpbslice = require("pb.slice")

return require('lib/tap')(function (test)
    test("null test", function (print, p, expect, uv)
        p(lpb, lpbio, lpbconv, lpbbuffer, lpbslice)
    end)
end)
