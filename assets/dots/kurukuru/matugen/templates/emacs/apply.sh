#!/usr/bin/env bash
set -euo pipefail

if command -v emacsclient &>/dev/null; then
    emacsclient -e "(load-theme 'flutterice t)" || true
fi