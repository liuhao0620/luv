extern "C"
{
#include "lua.h"
#include "lauxlib.h"
}

#include "tm.cpp"

static const luaL_Reg kLutlFunctions[] = 
{
	{ "getsystime", LutlGetSysTime },
	{ "sleep", LutlSleep },
	{ NULL, NULL }
};

extern "C"
{
	LUALIB_API int luaopen_lutl(lua_State * L)
	{
		luaL_newlib(L, kLutlFunctions);
		return 1;
	}
}
