LUV_TAG=$(shell git describe --tags)

ifdef WITHOUT_AMALG
	CMAKE_OPTIONS+= -DWITH_AMALG=OFF
endif

BUILD_MODULE ?= ON
BUILD_SHARED_LIBS ?= OFF
WITH_SHARED_LIBUV ?= OFF
WITH_LUA_ENGINE ?= Lua
LUA_BUILD_TYPE ?= Static


ifeq ($(WITH_LUA_ENGINE), LuaJIT)
  LUABIN=build/luajit
else
  LUABIN=build/lua
endif

CMAKE_OPTIONS += \
	-DBUILD_MODULE=$(BUILD_MODULE) \
	-DBUILD_SHARED_LIBS=$(BUILD_SHARED_LIBS) \
	-DWITH_SHARED_LIBUV=$(WITH_SHARED_LIBUV) \
	-DWITH_LUA_ENGINE=$(WITH_LUA_ENGINE) \
	-DLUA_BUILD_TYPE=$(LUA_BUILD_TYPE) \
	-DLUA_COMPAT53_DIR=deps/lua-compat-5.3

all: luv lkcp lpb lutl

deps/libuv/include:
	git submodule update --init deps/libuv

deps/luajit/src:
	git submodule update --init deps/luajit

build/Makefile: deps/libuv/include deps/luajit/src
	cmake -H. -Bbuild ${CMAKE_OPTIONS} 

luv: build/Makefile
	cmake --build build --config Debug
	ln -sf build/luv.so

lkcp:build/CMakeFiles/lkcp.dir/ build/CMakeFiles/lkcp.dir/ikcp.o build/CMakeFiles/lkcp.dir/lkcp.o build/liblua53.so 
	g++ -o2 -std=c++11 -shared -Ideps/kcp/ -Ideps/lua/ -Ideps/lua-compat-5.3/ -DLUA_BUILD_AS_DLL -DLUA_LIB -o build/lkcp.so build/CMakeFiles/lkcp.dir/ikcp.o build/CMakeFiles/lkcp.dir/lkcp.o build/liblua53.so 
	ln -sf build/lkcp.so

lpb:build/CMakeFiles/lpb.dir/ build/CMakeFiles/lpb.dir/pb.o build/liblua53.so
	g++ -o2 -std=c++11 -shared -Ideps/lua-protobuf/ -Ideps/lua/ -Ideps/lua-compat-5.3/ -DLUA_BUILD_AS_DLL -DLUA_LIB -o build/pb.so build/CMakeFiles/lpb.dir/pb.o build/liblua53.so
	ln -sf build/pb.so

lutl:build/CMakeFiles/lutl.dir/ build/CMakeFiles/lutl.dir/tm.o build/CMakeFiles/lutl.dir/lutl.o
	g++ -o2 -std=c++11 -shared -Ideps/lua/ -Ideps/lua-compat-5.3/ -DLUA_BUILD_AS_DLL -DLUA_LIB -o build/lutl.so build/CMakeFiles/lutl.dir/tm.o build/CMakeFiles/lutl.dir/lutl.o build/liblua53.so
	ln -sf build/lutl.so

clean:
	rm -rf build luv.so

test: luv
	${LUABIN} tests/run.lua

reset:
	git submodule update --init --recursive && \
	  git clean -f -d && \
	  git checkout .

publish-luarocks:
	rm -rf luv-${LUV_TAG}
	mkdir -p luv-${LUV_TAG}/deps
	cp -r src cmake CMakeLists.txt LICENSE.txt README.md docs.md luv-${LUV_TAG}/
	cp -r deps/libuv deps/*.cmake deps/lua_one.c luv-${LUV_TAG}/deps/
	COPYFILE_DISABLE=true tar -czvf luv-${LUV_TAG}.tar.gz luv-${LUV_TAG}
	github-release upload --user luvit --repo luv --tag ${LUV_TAG} \
	  --file luv-${LUV_TAG}.tar.gz --name luv-${LUV_TAG}.tar.gz
	luarocks upload luv-${LUV_TAG}.rockspec --api-key=${LUAROCKS_TOKEN}

build/CMakeFiles/lkcp.dir/:
	mkdir -p build/CMakeFiles/lkcp.dir/

build/CMakeFiles/lkcp.dir/ikcp.o:deps/kcp/ikcp.h deps/kcp/ikcp.c
	g++ -o2 -fPIC -Ideps/kcp/ -o $@ -c deps/kcp/ikcp.c

build/CMakeFiles/lkcp.dir/lkcp.o:deps/kcp/ikcp.h lua_extend/src/lkcp/lkcp.cpp deps/lua/
	g++ -o2 -std=c++11 -fPIC -Ideps/kcp/ -Ideps/lua/ -Ideps/lua-compat-5.3/ -o $@ -c lua_extend/src/lkcp/lkcp.cpp

build/CMakeFiles/lpb.dir/:
	mkdir -p build/CMakeFiles/lpb.dir/

build/CMakeFiles/lpb.dir/pb.o:deps/lua-protobuf/pb.c
	gcc -o2 -fPIC -Ideps/lua-protobuf/ -Ideps/lua/ -Ideps/lua-compat-5.3/ -o $@ -c deps/lua-protobuf/pb.c

build/CMakeFiles/lutl.dir/:
	mkdir -p build/CMakeFiles/lutl.dir/

build/CMakeFiles/lutl.dir/tm.o:lua_extend/src/lutl/tm.cpp deps/lua/
	g++ -o2 -std=c++11 -fPIC -Ideps/lua/ -Ideps/lua-compat-5.3/ -o $@ -c lua_extend/src/lutl/tm.cpp

build/CMakeFiles/lutl.dir/lutl.o:lua_extend/src/lutl/lutl.cpp deps/lua/
	g++ -o2 -std=c++11 -fPIC -Ideps/lua/ -Ideps/lua-compat-5.3/ -o $@ -c lua_extend/src/lutl/lutl.cpp
	

