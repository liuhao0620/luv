local llog = require("lspdlog")

local log = llog.create("test")
log:set_pattern("[%l][%T %D][%t]%v")
log:set_level("debug")
log:trace("hello world!")
log:debug("hello world!")
log:info("hello world!")
log:warn("hello world!")
log:error("hello world!")
log:critical("hello world!")
