.DEFAULT_GOAL := build

.PHONY: help all install test dev coverage clean gc build archive cloc

PROJECT_NAME := qemount_build

BUILD_PLATFORM ?= $(shell ./scripts/canonical_arch.sh)-linux
REGISTRY ?= localhost
export BUILD_PLATFORM
export REGISTRY

all: .venv/.installed-dev  ## build all locally buildable output platforms
	.venv/bin/qemount-build outputs --all-platforms | xargs -r .venv/bin/qemount-build build

install: .venv/.installed  ## install the venv and project packages

dev: .venv/.installed-dev  ## prepare local repo and venv for dev

test: .venv/.installed-dev  ## run the project's tests
	scripts/test.sh $(PROJECT_NAME)

coverage: .venv/.installed-dev scripts/coverage.sh  ## build the html coverage report
	scripts/coverage.sh $(PROJECT_NAME)

build: .venv/.installed-dev scripts/build.sh  ## build host-compatible outputs
	scripts/build.sh

clean:  ## delete caches and the venv
	scripts/clean.sh

gc: .venv/.installed-dev  ## collect obsolete qemount build state
	.venv/bin/qemount-build gc

dist: scripts/dist.sh  ## build the distributable files
	scripts/dist.sh $(PROJECT_NAME)

release: scripts/release.sh  ## publish to pypi
	scripts/release.sh $(PROJECT_NAME)

archive: scripts/archive.sh scripts/Dockerfile.archive scripts/archive-build.sh scripts/registries.archive.conf scripts/TIME_CAPSULE.md  ## build complete archive in container
	scripts/archive.sh

# Python project infrastructure
.venv/.installed: pyproject.toml .venv/bin/activate scripts/install.sh $(shell find src -name '*.py')
	scripts/install.sh $(PROJECT_NAME)

.venv/.installed-dev: pyproject.toml .venv/bin/activate scripts/install-dev.sh
	scripts/install-dev.sh $(PROJECT_NAME)

.venv/bin/activate:
	scripts/venv.sh

cloc: .venv/bin/cloc  ## count lines of code
	.venv/bin/cloc --vcs=git .

.venv/bin/cloc: .venv/bin/activate
	curl -sL https://raw.githubusercontent.com/AlDanial/cloc/refs/heads/master/cloc -o .venv/bin/cloc
	chmod +x .venv/bin/cloc

help:  ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
