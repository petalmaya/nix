#!/usr/bin/env bash
set -euo pipefail
# reload mako if running; makoctl reload reapplies config without restart
if pgrep -x mako >/dev/null 2>&1; then
  makoctl reload 2>/dev/null || pkill -x mako 2>/dev/null || true
fi
