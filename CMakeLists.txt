cmake_minimum_required(VERSION 2.6)
project(OldlandBootROM ASM)

set(CMAKE_ASM_COMPILER oldland-elf-as)
set(CMAKE_ASM_FLAGS "-I${CMAKE_CURRENT_SOURCE_DIR}")
set(CMAKE_ASM_LINK_EXECUTABLE "oldland-elf-ld <OBJECTS> -T ${CMAKE_CURRENT_SOURCE_DIR}/link.x -o <TARGET> <CMAKE_ASM_LINK_FLAGS> <LINK_FLAGS>")

add_executable(kernel
	       kernel.s
	       uart.s
	       string.s
	       sdram.s
	       putu.s
	       strcmp.s
	       help.s
	       buildid.s
	       shell.s
	       readmbr.s
	       bzero.s
	       memcpy.s)
