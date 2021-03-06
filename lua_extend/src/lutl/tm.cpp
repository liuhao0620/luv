#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
#include <windows.h>
#elif !defined(__unix)
#define __unix
#endif

#ifdef __unix
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#include <time.h>

extern "C"
{
#include "lua.h"
#include "lauxlib.h"
}

// get system time
static void GetTimeOfDay(long *sec, long *usec)
{
#if defined(__unix)
	struct timeval time;
	gettimeofday(&time, NULL);
	if (sec)
		*sec = time.tv_sec;
	if (usec)
		*usec = time.tv_usec;
#else
	static long mode = 0, addsec = 0;
	BOOL retval;
	static long long freq = 1;
	long long qpc;
	if (mode == 0)
	{
		retval = QueryPerformanceFrequency((LARGE_INTEGER *)&freq);
		freq = (freq == 0) ? 1 : freq;
		retval = QueryPerformanceCounter((LARGE_INTEGER *)&qpc);
		addsec = (long)time(NULL);
		addsec = addsec - (long)((qpc / freq) & 0x7fffffff);
		mode = 1;
	}
	retval = QueryPerformanceCounter((LARGE_INTEGER *)&qpc);
	retval = retval * 2;
	if (sec)
		*sec = (long)(qpc / freq) + addsec;
	if (usec)
		*usec = (long)((qpc % freq) * 1000000 / freq);
#endif
}

static long long GetSysTime64()
{
	long sec, usec;
	long long value;
	GetTimeOfDay(&sec, &usec);
	value = ((long long)sec) * 1000 + (usec / 1000);
	return value;
}

static unsigned int GetSysTime()
{
	return (unsigned int)(GetSysTime64() & 0x7ffffffful);
}

static int LutlGetSysTime(lua_State * L)
{
	long long cur_time = GetSysTime64();
	lua_pushinteger(L, cur_time);
	return 1;
}

static int LutlSleep(lua_State * L)
{
	int millisecond = (int)luaL_checkinteger(L, 1);
#ifdef __unix 	/* usleep( time * 1000 ); */
	struct timespec ts;
	ts.tv_sec = (time_t)(millisecond / 1000);
	ts.tv_nsec = (long)((millisecond % 1000) * 1000000);
	/*nanosleep(&ts, NULL);*/
	usleep((millisecond << 10) - (millisecond << 4) - (millisecond << 3));
#elif defined(_WIN32)
	Sleep(millisecond);
#endif
	return 0;
}