#!/usr/bin/env bash
# Mock greeter preview in the current session (hot reload); NIXTOP_SHELL_GREETER_MOCK=1 fakes greetd, see Data/Greeter.qml.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[INFO] Launching greeter.qml in mock mode - press Escape in the greeter to quit"
echo "[INFO] (Ctrl+C may not reach this terminal while the greeter has keyboard focus)"
echo "[INFO] Real greetd is NOT involved - nothing here can actually log you out/in"

NIXTOP_SHELL_GREETER_MOCK=1 exec quickshell -p "$REPO_ROOT/greeter.qml"
