# JES — Just Enough Shell (vendored fork)

Forked from <https://github.com/ORFLEM/just_enough_shell> at `d121251`
(see `UPSTREAM`). Fast & minimal Quickshell desktop shell for Wayland WMs,
with its own bar, launcher, power menu, notifications, wallpaper picker and
Go helpers (music, calendar, cava, launcher, screenpicker).

## Layout

- `shell/` — upstream `.local/JES/quickshell` (QML + scripts + prebuilt Go
  helpers). Installed to `~/.local/JES/quickshell` so `jes-cli` paths work
  unchanged. Prebuilt ELFs (`scripts/music`, `scripts/cal`,
  `scripts/Cava-internal`, `launcher/launch`, …) are upstream builds;
  `go/` holds the upstream Go sources to rebuild them with Nix later.
  Note: upstream symlink `shell/JES/Helpers -> ../helpers` is stored here
  as a real copy — Windows checkouts cannot index that symlink, and the
  QML `JES.Helpers` module import resolves identically either way.
  (The `shell/JES/Bar -> ../bar` copy was dead — nothing imports module
  `JES.Bar` — so it was deleted.) Re-copy (don't re-symlink)
  when updating the fork.
- `config/` — upstream `.config/JES` (`config.toml`, `wallpaper.toml`,
  `waypoints.json`, `base16.json`). Installed to `~/.config/JES/`.
- `matugen/colors.json` — upstream JES matugen template, rendered by our
  matugen registry (`jes` template) to `~/.local/state/JES_colors.json`,
  which `shell.qml` watches. JES stays themed via `nixtop-theme <image>`.
- `go/` — upstream `for-quickshell/go` sources (reference for Nix builds).
- `sway/keybinds.conf` — JES keybinds for swayfx, included via
  `modules/sway` `variant.conf` when `nixtop.shell == "jes"`.
- `jes-cli` — upstream CLI, packaged on PATH via `writeShellScriptBin`
  (upstream drops it in `~/.local/bin`, which sway's exec PATH lacks).
- `package.nix` — `qs` wrapper + runtime deps for JES.
- `default.nix` — HM module, enabled only when `nixtop.shell == "jes"`.

## Selection

`nixtop.shell = "jes"` (default stays `"none"` = waybar-only). JES is
mutually exclusive with noctalia/quickshell/waybar: sway's variant execs
`jes-cli start-daemon` and skips waybar+mako autostart, since JES owns the
bar and notifications.

## Updating

```sh
git clone https://github.com/ORFLEM/just_enough_shell.git /tmp/jes
# copy .local/JES/quickshell -> shell/, .config/JES -> config/,
# .local/bin/jes-cli -> jes-cli, for-quickshell/go -> go/
git -C /tmp/jes rev-parse HEAD > UPSTREAM
```
