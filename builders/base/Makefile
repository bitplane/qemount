# builders/base/Makefile
ARCH ?= $(shell uname -m)
IMAGE_NAME := qemount-builder-base
IMAGE_TAG := $(ARCH)
LOCK_FILE := .base-builder-$(ARCH).lock

.PHONY: all clean

all: $(LOCK_FILE)

# The lock file depends on the Dockerfile - if Dockerfile changes, rebuild
$(LOCK_FILE): Dockerfile
	podman build \
		--build-arg ARCH=$(ARCH) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		.
	# Create lock file with timestamp to track when image was built
	date > $(LOCK_FILE)

clean:
	rm -f $(LOCK_FILE)
	podman rmi -f $(IMAGE_NAME):$(IMAGE_TAG) || true