# mk/common.mk - Variables and Configuration

# Paths & Configuration
TARGET_ARCH ?= $(error TARGET_ARCH is not set)
OUTPUT_DIR  ?= $(error OUTPUT_DIR is not set)
CACHE_DIR   ?= $(error CACHE_DIR is not set)

# Guest Configuration
GUEST_NAME := linux-6.11
KERNEL_VERSION := 6.11
BUSYBOX_VERSION := 1.36.1

# Architecture Setup
KERNEL_ARCH := $(TARGET_ARCH)
export ARCH := $(KERNEL_ARCH)

# Source Directories
SOURCE_ROOTFS_DIR := rootfs
SCRIPT_DIR := scripts

# Build & Output Directories
KERNEL_BUILD_DIR := $(CACHE_DIR)/$(GUEST_NAME)-kernel-$(TARGET_ARCH)-build
BUSYBOX_SRC_DIR := $(CACHE_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_INSTALL_DIR := $(CACHE_DIR)/$(GUEST_NAME)-busybox-$(TARGET_ARCH)-install
STAGING_ROOTFS_DIR := $(CACHE_DIR)/$(GUEST_NAME)-rootfs-$(TARGET_ARCH)-staging

# Output Files
FINAL_KERNEL_NAME := kernel
FINAL_KERNEL := $(OUTPUT_DIR)/$(FINAL_KERNEL_NAME)
FINAL_INITRAMFS := $(OUTPUT_DIR)/initramfs.cpio.gz
FINAL_RUN_SH := $(OUTPUT_DIR)/run.sh
FINAL_META_CONF := $(OUTPUT_DIR)/meta.conf