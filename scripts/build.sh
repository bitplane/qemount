#!/usr/bin/env bash

source .venv/bin/activate

qemount-build outputs | xargs -r qemount-build build
