#!/usr/bin/env bash
set -euo pipefail

if command -v bat &>/dev/null; then
    bat cache --build &>/dev/null || true
fi
