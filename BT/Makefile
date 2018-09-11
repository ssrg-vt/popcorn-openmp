NPB_COMMON	:= $(shell readlink -f ../common/npb)
NPB_SRC			:= $(shell ls $(NPB_COMMON)/*.c)
NPB_OBJ			:= $(NPB_SRC:.c=.o)
CFLAGS			:= -I$(NPB_COMMON)

CLASS		?= C
BIN 		:= BT-$(CLASS)
C_SRC 	:= $(shell ls *.c) $(NPB_SRC)
APP_DIR := $(shell pwd)

DEPS	:= npbparams.h
TRASH	:= $(DEPS) BT-* $(NPB_OBJ)

include ../Makefile

npbparams.h:
	@echo "-> Building BT class $(shell echo $(CLASS) | tr a-z A-Z) <-"
	@cp npbparams-$(shell echo $(CLASS) | tr a-z A-Z).h npbparams.h

