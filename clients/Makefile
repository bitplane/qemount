# Makefile for building all client applications
ARCH ?= $(shell uname -m)

# Get a list of all client directories
CLIENTS := $(wildcard *)

# Filter out non-directories and this directory
CLIENTS := $(filter-out Makefile, $(CLIENTS))

# Default target - build all clients
.PHONY: all
all: $(CLIENTS)

# Target to build a specific client
.PHONY: $(CLIENTS)
$(CLIENTS):
	@echo "Building client: $@"
	$(MAKE) -C $@ ARCH=$(ARCH)

# Clean all clients
.PHONY: clean
clean:
	@for client in $(CLIENTS); do \
		echo "Cleaning client: $$client"; \
		$(MAKE) -C $$client clean ARCH=$(ARCH); \
	done

# Add a list target to show available clients
.PHONY: list
list:
	@echo "Available clients:"
	@echo "$(CLIENTS)" | tr ' ' '\n' | sed 's/^/  /'