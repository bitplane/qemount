# Top-level Makefile for qemount
.PHONY: all clean refresh list

# Default architecture if not set
ARCH ?= $(shell uname -m)
export ARCH

all: build/Makefile
	@$(MAKE) -C build all

build/Makefile:
	@./generate_makefiles.py

clean: build/Makefile
	@$(MAKE) -C build clean

refresh:
	#@find build -type f -name 'Makefile' -print0 | xargs -0 rm
	@./generate_makefiles.py

list: build/Makefile
	@$(MAKE) -C build list
