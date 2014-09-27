cmake_minimum_required(VERSION 2.6)
project(OldlandBootROM ASM C)

set(CMAKE_SYSTEM_NAME none)
set(CMAKE_SYSTEM_PROCESSOR oldland)
set(CMAKE_C_COMPILER oldland-elf-gcc)
set(CMAKE_ASM_COMPILER oldland-elf-as)

set(CMAKE_C_FLAGS "-Wall -Werror -ffreestanding -O2 -ggdb3")
set(CMAKE_ASM_FLAGS "-I${CMAKE_CURRENT_SOURCE_DIR}/src")

SET(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "-nostdlib -T ${CMAKE_CURRENT_SOURCE_DIR}/src/link.x -Wl,-EL -lgcc")

add_executable(kernel
	       src/entry.s
	       src/sdram.s
	       src/kernel.c
	       src/uart.c
	       src/string.c
	       src/shell.c
	       src/printk.c
	       src/buildid.c
	       src/readmbr.c
	       src/cpuinfo.c
	       src/reset.c)
