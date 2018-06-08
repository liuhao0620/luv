extern "C"
{
#include "lua.h"
#include "lauxlib.h"
}

#include "spdlog.h"

static int LspdlogSimpleTest(lua_State * L)
{
	std::string filename = "build/simple_test.log";

	auto logger = spdlog::create<spdlog::sinks::simple_file_sink_mt>("simpletest_logger", filename);
	logger->set_pattern("%v");
	logger->set_level(spdlog::level::trace);
	logger->flush_on(spdlog::level::info);
	logger->trace("Should not be flushed");

#if !defined(SPDLOG_FMT_PRINTF)
	logger->info("Test message {}", 1);
	logger->info("Test message {}", 2);
#else
	logger->info("Test message %d", 1);
	logger->info("Test message %d", 2);
#endif
	logger->flush();
	return 0;
}

static const luaL_Reg kLspdlogFunctions[] =
{
	{"simpletest", LspdlogSimpleTest },
	{ NULL, NULL }
};

extern "C"
{
	LUALIB_API int luaopen_lspdlog(lua_State * L)
	{
		luaL_newlib(L, kLspdlogFunctions);
		return 1;
	}
}