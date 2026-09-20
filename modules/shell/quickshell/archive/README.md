# Archived — Mango Quickshell

This directory archives the Mango-specific quickshell bits that were primary
before the Sway port (2026-09).

- `MangoWC.qml` — Mango IPC via `mmsg watch all-monitors`. Kept for reference;
  the live shell now uses `Data/Sway.qml` (Go daemon + FileView) when running
  under swayfx. MangoWC is still present at `shell/Data/MangoWC.qml` but
  `Shell.qml` prefers `Sway` when `Sway.active` is true.

- `../shell/Data/MangoWC.qml` — still the mango backend; not deleted so the
  `mango` compositor session (via `programs.mango` + SDDM) keeps working if
  you switch back. To fully remove mango, delete this file and the
  `modules/mango/` variants, then drop the `mango` input from `flake.nix`.

Sway is now primary:

- `Data/Sway.qml` — sway IPC via `nixtop-sway-ipc` (Go, `modules/shell/quickshell/ipc/daemon.go`).
  Mirrors `MangoWC`'s shape (`focusedOutput`, `currentWorkspace`, `workspaces`,
  `currentWorkspaceByOutput`) so widgets (`WorkspacePill`, `SystemView`,
  `LauncherWorkspaces`, `Globals`) can swap backends with `Sway.active ? Sway : MangoWC`.

- `ipc/` — Go daemon (caelestia/dank pattern). Holds one sway IPC socket,
  subscribes to `workspace/window/output/mode/binding`, writes a compact
  snapshot to `~/.cache/nixtop-shell/sway.json`. QML just `FileView`s it,
  avoiding per-frame `swaymsg` forks.

To re-enable mango quickshell: set `nixtop.shell = "quickshell"` and
`nixtop.quickshell.compositor = "mango"` in your host/user config, and ensure
`XDG_CURRENT_DESKTOP=mango` (mango session). The archived `MangoWC.qml` will
be picked again.

To switch back to waybar-only (no shell): `nixtop.shell = "none"` (default)
and `nixtop.sway.bar = "waybar"` (default). Waybar is the bar; matugen owns
`sway`, `waybar`, `fuzzel`, `mako` themes via `matugen image`.
