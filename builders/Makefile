# Top-level Makefile for builders

# Determine directory paths
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(SELF_DIR)/..)
BUILDER_DIR := $(abspath $(SELF_DIR))
CACHE_ROOT := $(PROJECT_ROOT)/build/cache
BUILD_ROOT := $(PROJECT_ROOT)/build

# Default architecture
ARCH ?= $(shell uname -m)

# Export these variables so they're available to included makefiles
export PROJECT_ROOT
export BUILDER_DIR
export CACHE_ROOT
export BUILD_ROOT
export ARCH

# Create required directories
$(shell mkdir -p $(CACHE_ROOT) $(BUILD_ROOT))

# Default target builds all builders
.PHONY: all
all: base native

# Base builder
.PHONY: base
base:
	$(MAKE) -C $(BUILDER_DIR)/base

# Native builder (depends on base)
.PHONY: native
native: base
	$(MAKE) -C $(BUILDER_DIR)/native

# Clean all builders
.PHONY: clean
clean:
	$(MAKE) -C $(BUILDER_DIR)/native clean
	$(MAKE) -C $(BUILDER_DIR)/base clean

# Print variables for debugging
.PHONY: info
info:
	@echo "PROJECT_ROOT: $(PROJECT_ROOT)"
	@echo "BUILDER_DIR: $(BUILDER_DIR)"
	@echo "CACHE_ROOT: $(CACHE_ROOT)"
	@echo "BUILD_ROOT: $(BUILD_ROOT)"
	@echo "ARCH: $(ARCH)"