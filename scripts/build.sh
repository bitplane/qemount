#!/usr/bin/env bash

source .venv/bin/activate

qemount-build outputs | xargs qemount-build build
