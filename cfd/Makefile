THREADS		:= 128

BIN 			:= euler3d_cpu
CXX_SRC		:= $(shell ls *.cpp)
APP_DIR 	:= $(shell pwd)
CXXFLAGS	:= -DOPEN -Dblock_length=$(THREADS) -fno-exceptions
OPT				:= -O0

include ../Makefile

