# Include the generated Makefile if it exists
-include build/Makefile

# Default architecture if not set
ARCH ?= $(shell uname -m)
export ARCH

all: build/Makefile
	@$(MAKE) -C build all

# Auto-regenerate on metadata changes
build/Makefile: common/scripts/generate_makefiles.py $(shell find . -name "inputs.txt" -o -name "outputs.txt" -o -name "Dockerfile" -o -name "build.sh")
	@./common/scripts/generate_makefiles.py
