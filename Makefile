# Top-level Makefile for qemount
# Builds all guests and clients

# Default target
.PHONY: all
all: guests clients

# Build all guests
.PHONY: guests
guests:
	$(MAKE) -C guests all

# Build all clients
.PHONY: clients
clients:
	$(MAKE) -C clients all

# Clean everything
.PHONY: clean
clean:
	$(MAKE) -C guests clean
	$(MAKE) -C clients clean

# Show help
.PHONY: help
help:
	@echo "qemount - Mount anything to anything via QEMU"
	@echo ""
	@echo "Usage:"
	@echo "  make all       - Build all guests and clients"
	@echo "  make guests    - Build all guest systems"
	@echo "  make clients   - Build all client applications"
	@echo "  make clean     - Clean all build artifacts"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Cross-compilation:"
	@echo "  make ARCH=arm64 all  - Build for ARM64 architecture"
	@echo "  make ARCH=riscv64 guests - Build guests for RISC-V architecture"
	@echo ""
	@echo "Available architectures: x86_64, arm64/aarch64, arm, riscv64"