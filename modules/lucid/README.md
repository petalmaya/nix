# Lucid — Material-3 Quickshell shell on mango

Upstream: <https://github.com/Sn3akyy1/lucid> by Sn3akyy1, MIT licensed
(see `UPSTREAM` for the pin and update command, and the Credits section in
`README.org`). A bar, morphing dock/launcher, desktop widgets, lock screen,
emoji picker, screenshots, OSD, polkit agent, and a settings app — themed
together from the wallpaper via matugen.

## How it is tracked

The shell tree is **never vendored here**. `lucid` is a flake input
(`flake = false`), and activation copies it to `~/.config/quickshell`,
refreshing on upstream `VERSION` change while preserving state
(`UPSTREAM`, `default.nix` `ensureLucidShell`). So:

```sh
nix flake lock --update-input lucid  # pull upstream, then rebuild
```

A file does nothing because it exists here — only these layers adapt
upstream to this repo:

- `default.nix` — HM module (`nixtop.lucid.enable` follows `nixtop.shell`,
  `nixtop.lucid.compositor`, default `mango`), matugen twins
  (`lucid-shell` colors → `~/.cache/quickshell/matugen.json`,
  `lucid-starship` prompt; base `starship` template stands down), and the
  copy/seed activation.
- `package.nix` — `lucid-qs` wrapper (quickshell + QML import paths incl.
  `qt5compat` + runtime bins), JES-pattern.
- `../mango/variants/lucid/` — mango `appearance`/`keybinds`/`autostart`.
  Keybinds translate upstream `support/hypr/modules/binds.lua` to mango
  syntax; terminal is **foot**, not kitty; file manager stays nautilus;
  browser is chromium (current config, not upstream Zen); workspaces become
  mango tags (6). IPC uses `lucid-qs ipc call -- <target> <fn>`.
- prefs seed — upstream `defaults/prefs.json` with one mango tweak applied
  at seed time via jq: `showWorkspaces = false` (that bar module is
  `Quickshell.Hyprland`-only). Fresh installs only; change it in Settings.

## Foot over kitty (and other current-config layers)

- Mango binds spawn `foot`; nothing in our integration launches kitty, and
  the wrapper carries `foot` on PATH.
- Glass-slider terminal opacity only drives kitty upstream (`Glass.qml`
  writes `~/.config/kitty/lucid-glass.conf`); with foot it is inert — foot
  transparency stays at the static `alpha` in `modules/conf/foot.nix`.
- GTK/icon/cursor/fonts stay with our matugen + conf modules (Lucid's
  `--no-look` path, effectively): Lucid's Environment page may offer to own
  them, but our files remain the source of truth — re-read/keep per-tool.
- `nixtop-theme <image>` remains the wallpaper entry: it runs matugen,
  which rewrites `matugen.json`, which the shell watches live.

## Degraded on mango (Hyprland-only upstream, kept, not ported)

- Workspaces bar module (seeded off): live Hyprland previews, special
  workspaces/scratchpads, workspace overview drag-and-drop.
- Idle page ladder (owns `hypridle.conf`), per-app Glass rules (Hyprland
  window rules), Displays page (`lucid-monitors.lua`), Environment page
  Hyprland-env writes, `hyprpicker` color pick (needs Hyprland).
- SDDM login theme (`support/sddm`) is not installed; greeter stays SilentSDDM.

## Selection

`nixtop.shell = "lucid"` (alice). Mutually exclusive with
noctalia/quickshell/jes: the mango variant autostarts `lucid-qs` and skips
waybar+mako, since Lucid owns the bar and notifications.
