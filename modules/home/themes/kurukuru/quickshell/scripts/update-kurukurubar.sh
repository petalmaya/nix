#!/usr/bin/env bash
# Update the plain-checkout kurukurubar install used by greetd.
# Run with sudo (it needs to write into /etc/greetd/kurukurubar).
set -euo pipefail

REPO_DIR="/etc/greetd/kurukurubar"

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo." >&2
    exit 1
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "No git checkout found at $REPO_DIR - is this the plain-checkout install?" >&2
    exit 1
fi

echo "==> Fetching updates in $REPO_DIR"
git -C "$REPO_DIR" fetch origin

# Show what's changing before touching anything, so you can bail if a
# greeter.qml/Data/*.qml change looks scary.
echo "==> Changes since last update:"
git -C "$REPO_DIR" log --oneline HEAD..origin/main || true

read -rp "Proceed with pull? [y/N] " ans
if [[ "${ans,,}" != "y" ]]; then
    echo "Aborted, nothing changed."
    exit 0
fi

git -C "$REPO_DIR" pull origin main

echo "==> Re-applying read permissions for the greeter user"
chmod -R go+rX "$REPO_DIR"

echo "==> Done. Restart greetd to pick up changes:"
echo "    sudo systemctl restart greetd"
echo "(only do this from a spare TTY / when not mid-login, same caution as initial setup)"
