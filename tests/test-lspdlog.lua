local llog = require("lspdlog")

return require('lib/tap')(function (test)
    test("simple test", function (print, p, expect, uv)
        llog.simpletest()
    end)
end)