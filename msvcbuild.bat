@echo off

set VS=15
if "%configuration%"=="2015" (set VS=14)
if "%configuration%"=="2013" (set VS=12)

if not defined platform set platform=x64
if "%platform%" EQU "x64" (set VS=%VS% Win64)

set LUA_ENGINE=Lua
if "%1"=="" (set LUA_ENGINE=Lua) else (set LUA_ENGINE=%1)

cmake -H. -Bbuild -DWITH_LUA_ENGINE=%LUA_ENGINE% -G"Visual Studio %VS%"
cmake --build build --config Release
del luajit.exe
del lua.exe
del lua.exp
del luv.dll
copy build\Release\luv.dll .
if "%LUA_ENGINE%"=="LuaJIT" (copy build\Release\luajit.exe .) 
if "%LUA_ENGINE%"=="Lua" (copy build\Release\lua.exp .)
if "%LUA_ENGINE%"=="Lua" (copy build\Release\lua.exe .)
