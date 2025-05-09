# Makefile for building all guest systems
ARCH ?= $(shell uname -m)

# Get a list of all guest directories
GUESTS := $(wildcard *)

# Filter out non-directories and this directory
GUESTS := $(filter-out Makefile, $(GUESTS))

# Default target - build all guests
.PHONY: all
all: $(GUESTS)

# Target to build a specific guest
.PHONY: $(GUESTS)
$(GUESTS):
	@echo "Building guest: $@"
	$(MAKE) -C $@ ARCH=$(ARCH)

# Clean all guests
.PHONY: clean
clean:
	@for guest in $(GUESTS); do \
		echo "Cleaning guest: $$guest"; \
		$(MAKE) -C $$guest clean ARCH=$(ARCH); \
	done

# Add a list target to show available guests
.PHONY: list
list:
	@echo "Available guests:"
	@echo "$(GUESTS)" | tr ' ' '\n' | sed 's/^/  /'