extern "C"
{
#include "lua.h"
#include "lauxlib.h"
}

#include "spdlog.h"

// create options
static const char *const kLspdlogCreateModes[] = {
	"stdout_mt", "stdout_st", "basic_mt", "basic_st",
	"rotating_mt", "rotating_st", "daily_mt", "daily_st", NULL
};

// level options
static const char *const kLspdlogLogLevels[] = {
	"trace", "debug", "info", "warn", "error", "critical", "off", NULL
};

static spdlog::logger * LspdlogCheckLspdLogger(lua_State * L, int index)
{
	spdlog::logger * logger = *(spdlog::logger **)luaL_checkudata(L, index, "lspdlogger");
	luaL_argcheck(L, logger != NULL, index, "Expected lspdlogger");
	return logger;
}

// create logger
static int LspdlogCreate(lua_State * L)
{
	enum LspdlogCreateMode
	{
		LCM_STDOUT_MT = 0,
		LCM_STDOUT_ST,
		LCM_BASIC_MT,
		LCM_BASIC_ST,
		LCM_ROTATING_MT,
		LCM_ROTATING_ST,
		LCM_DAILY_MT,
		LCM_DAILY_ST,
	};
	const char * logger_name = luaL_checkstring(L, 1);
	int mode = luaL_checkoption(L, 2, "stdout_mt", kLspdlogCreateModes);
	std::shared_ptr<spdlog::logger> logger;
	switch ((LspdlogCreateMode)mode)
	{
	case LCM_STDOUT_MT:
	{
		logger = spdlog::stdout_logger_mt(logger_name);
	}
		break;
	case LCM_STDOUT_ST:
	{
		logger = spdlog::stdout_logger_st(logger_name);
	}
		break;
	case LCM_BASIC_MT:
	{
		const char * file_name = luaL_checkstring(L, 3);
		bool truncate = false;
		if (lua_gettop(L) >= 4 && lua_toboolean(L, 4))
		{
			truncate = true;
		}
		logger = spdlog::basic_logger_mt(logger_name, file_name, truncate);
	}
		break;
	case LCM_BASIC_ST:
	{
		const char * file_name = luaL_checkstring(L, 3);
		bool truncate = false;
		if (lua_gettop(L) >= 4 && lua_toboolean(L, 4))
		{
			truncate = true;
		}
		logger = spdlog::basic_logger_st(logger_name, file_name, truncate);
	}
		break;
	case LCM_ROTATING_MT:
	{
		const char * file_name = luaL_checkstring(L, 3);
		size_t max_file_size = (size_t)luaL_checkinteger(L, 4);
		size_t max_files = (size_t)luaL_checkinteger(L, 5);
		logger = spdlog::rotating_logger_mt(logger_name, file_name, max_file_size, max_files);
	}
		break;
	case LCM_ROTATING_ST:
	{
		const char * file_name = luaL_checkstring(L, 3);
		size_t max_file_size = (size_t)luaL_checkinteger(L, 4);
		size_t max_files = (size_t)luaL_checkinteger(L, 5);
		logger = spdlog::rotating_logger_st(logger_name, file_name, max_file_size, max_files);
	}
		break;
	case LCM_DAILY_MT:
	{
		const char * file_name = luaL_checkstring(L, 3);
		int hour = 0, minute = 0;
		if (lua_gettop(L) >= 4)
		{
			hour = (int)luaL_checkinteger(L, 4);
		}
		if (lua_gettop(L) >= 5)
		{
			minute = (int)luaL_checkinteger(L, 5);
		}
		logger = spdlog::daily_logger_mt(logger_name, file_name, hour, minute);
	}
		break;
	case LCM_DAILY_ST:
	{
		const char * file_name = luaL_checkstring(L, 3);
		int hour = 0, minute = 0;
		if (lua_gettop(L) >= 4)
		{
			hour = (int)luaL_checkinteger(L, 4);
		}
		if (lua_gettop(L) >= 5)
		{
			minute = (int)luaL_checkinteger(L, 5);
		}
		logger = spdlog::daily_logger_st(logger_name, file_name, hour, minute);
	}
		break;
	default:
		break;
	}
	*(spdlog::logger **)lua_newuserdata(L, sizeof(void *)) = logger.get();
	luaL_getmetatable(L, "lspdlogger");
	lua_setmetatable(L, -2);
	return 1;
}

static int LspdlogSetPattern(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * pattern = luaL_checkstring(L, 2);
	logger->set_pattern(pattern);
	return 0;
}

static int LspdlogSetLevel(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	int level = luaL_checkoption(L, 2, "trace", kLspdlogLogLevels);
	logger->set_level(spdlog::level::level_enum(level));
	return 0;
}

static int LspdlogFlushOn(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	int level = luaL_checkoption(L, 2, "trace", kLspdlogLogLevels);
	logger->flush_on(spdlog::level::level_enum(level));
	return 0;
}

static int LspdlogFlush(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	logger->flush();
	return 0;
}

static int LspdlogTrace(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * log_str = luaL_checkstring(L, 2);
	logger->trace(log_str);
	return 0;
}

static int LspdlogDebug(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * log_str = luaL_checkstring(L, 2);
	logger->debug(log_str);
	return 0;
}

static int LspdlogInfo(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * log_str = luaL_checkstring(L, 2);
	logger->info(log_str);
	return 0;
}

static int LspdlogWarn(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * log_str = luaL_checkstring(L, 2);
	logger->warn(log_str);
	return 0;
}

static int LspdlogError(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * log_str = luaL_checkstring(L, 2);
	logger->error(log_str);
	return 0;
}

static int LspdlogCritical(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	const char * log_str = luaL_checkstring(L, 2);
	logger->critical(log_str);
	return 0;
}

static int LspdLoggerTostring(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	lua_pushfstring(L, "lspdlogger: %p", logger);
	return 1;
}

static int LspdLoggerGc(lua_State * L)
{
	spdlog::logger * logger = LspdlogCheckLspdLogger(L, 1);
	spdlog::drop(logger->name());
	return 0;
}

static const luaL_Reg kLspdlogFunctions[] =
{
	{"create", LspdlogCreate},
	{ NULL, NULL }
};

static const luaL_Reg kLspdLoggerFunctions[] = 
{
	{"set_pattern", LspdlogSetPattern },
	{"set_level", LspdlogSetLevel },
	{"flush_on", LspdlogFlushOn },
	{"flush", LspdlogFlush },
	{"trace", LspdlogTrace },
	{"debug", LspdlogDebug },
	{"info", LspdlogInfo },
	{"warn", LspdlogWarn },
	{"error", LspdlogError },
	{"critical", LspdlogCritical },
	{NULL, NULL}
};

extern "C"
{
	LUALIB_API int luaopen_lspdlog(lua_State * L)
	{
		// init lspdlog metatable
		luaL_newmetatable(L, "lspdlogger");
		lua_pushcfunction(L, LspdLoggerTostring);
		lua_setfield(L, -2, "__tostring");
		lua_pushcfunction(L, LspdLoggerGc);
		lua_setfield(L, -2, "__gc");
		lua_newtable(L);
		luaL_setfuncs(L, kLspdLoggerFunctions, 0);
		lua_setfield(L, -2, "__index");
		lua_pop(L, 1);
		
		luaL_newlib(L, kLspdlogFunctions);
		return 1;
	}
}