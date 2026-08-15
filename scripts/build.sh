#!/usr/bin/env bash

source .venv/bin/activate

mountin-build outputs | xargs -r mountin-build build
