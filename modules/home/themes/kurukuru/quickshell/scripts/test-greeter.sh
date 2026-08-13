#!/usr/bin/env bash
# Runs greeter.qml in your current, already-logged-in niri/mangowc session
# instead of through greetd - so you can iterate on the look/feel with
# normal hot reload instead of restarting greetd (or a nested compositor)
# every time. Sets KURU_GREETER_MOCK=1 so Data/Greeter.qml fakes the
# createSession/authMessage/launch round trip instead of touching a real
# (almost certainly absent, outside an actual greetd session) greetd
# socket - see Data/Greeter.qml and handoff.md for what mock mode does
# and doesn't cover.
#
# Usage: scripts/test-greeter.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[INFO] Launching greeter.qml in mock mode - press Escape in the greeter to quit"
echo "[INFO] (Ctrl+C may not reach this terminal while the greeter has keyboard focus)"
echo "[INFO] Real greetd is NOT involved - nothing here can actually log you out/in"

KURU_GREETER_MOCK=1 exec quickshell -p "$REPO_ROOT/greeter.qml"
