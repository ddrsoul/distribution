# CMake toolchain: Debian's aarch64 cross compilers, libraries from the arm64
# multiarch packages (libsdl3-dev:arm64, libvulkan-dev:arm64).
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_AR /usr/bin/aarch64-linux-gnu-ar CACHE FILEPATH "")
set(CMAKE_NM /usr/bin/aarch64-linux-gnu-nm CACHE FILEPATH "")
set(CMAKE_RANLIB /usr/bin/aarch64-linux-gnu-ranlib CACHE FILEPATH "")
set(CMAKE_STRIP /usr/bin/aarch64-linux-gnu-strip CACHE FILEPATH "")

# RK3566: four Cortex-A55 cores.
set(CMAKE_C_FLAGS_INIT "-mcpu=cortex-a55")
set(CMAKE_CXX_FLAGS_INIT "-mcpu=cortex-a55")

set(CMAKE_LIBRARY_ARCHITECTURE aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig")
