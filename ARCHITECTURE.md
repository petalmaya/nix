# How this configuration is wired (v2)

This file is the map for the reworked repository.

```text
flake.nix
├── chooses a host (wonderland / rabbit / garden)
├── imports that host's hardware file and default.nix + disko.nix
├── imports (import ./modules/default.nix).nixosModules  – system modules
└── adds Home Manager and imports (import ./modules/default.nix).homeModules – HM modules
    └── each user's modules/user/<name>/home.nix turns modules on/off
```

A file does nothing because it exists – it must be imported via `modules/default.nix` and, if it has an `enable` option, enabled by host or user.

## Start here

| Want to change... | Edit... |
|---|---|
| Which machines can be built | `flake.nix`, `nixosConfigurations` |
| Which user is on a machine | `flake.nix`, the `hmUsers` argument to `mkHost` |
| Machine-specific settings | `hosts/<machine>/default.nix` |
| Disk layout | `hosts/<machine>/disko.nix` |
| Shared OS policy | `modules/core/default.nix` |
| Which custom system modules exist | `modules/default.nix` (`nixosModules`) |
| Which custom HM modules exist | `modules/default.nix` (`homeModules`) |
| What Alice / Lewis / Rose gets | `modules/user/<name>/home.nix` |
| A HM module's implementation | `modules/{browsers,conf,emacs,mango,matugen,shell,shell/{noctalia,quickshell,jes},sway}` |
| Theme files and shell config | `modules/mango`, `modules/matugen/templates`, `modules/shell/quickshell/shell` |
| Flake inputs and pins | `flake.nix` and `flake.lock` |
| Encrypted values | `secrets/` and `.sops.yaml` |

## System layers

### `flake.nix`

Pins external inputs (`nixpkgs` 26.05, `nixpkgs-unstable`, `home-manager`, `nix-flatpak`, `disko`, `sops-nix`, `noctalia-shell`/`noctalia-greeter`, `nixmacs`/`emacs-overlay`, `firefox-addons`, `quickshell`, `nixpak`, `mango`), creates the three `nixosConfigurations`, passes `inputs`/`unstable-pkgs`/`self`, imports each host's `hardware-configuration.nix` + `default.nix` + `disko.nix`, imports `modules/default.nix`, and configures Home Manager (`useGlobalPkgs`, `users = hmUsers`, `sharedModules`).

`garden` is a real host with a default btrfs `disko.nix` and `zswap` (not `zram`); its `hardware-configuration.nix` is a placeholder until the laptop is installed – `nix build .#garden` is expected to fail until then.

### `hosts/<name>/`

- `hardware-configuration.nix`: generated hardware facts (carried over for wonderland/rabbit, placeholder for garden).
- `default.nix`: hostname, firmware, bluetooth, locale, `nixtop.desktop.enable`, host-specific sops/wifi, `zram`/`zswap` policy.
- `disko.nix`: declarative disk layout (btrfs subvolumes). `rabbit` keeps an empty stub so `flake.nix` can import it uniformly.

`hardware-configuration.nix` and `disko.nix` are imported by `flake.nix`, not by `hosts/<host>/default.nix`, to avoid double-import.

### `hosts/common/` (gone)

Old shared policy lived in `hosts/common/default.nix`. In v2 it is `modules/core/default.nix` – bootloader, binfmt, networking, timezone, ssh, `allowUnfree`, `mutableUsers`, users+groups, **sops**, oomd, `zram`/`zswap`, swap, sysctl, fonts, pipewire, graphics, desktop switch, greeter default (`nixtop.shell` → `nixtop.greetd.greeter`), and dev flag defaults.

### `modules/nixos` → `modules/core`

| File | Controls |
|---|---|
| `core/cachix.nix` | Imports every cache file in `core/cachix/` (`nix-community`, `noctalia`) |
| `core/default.nix` | System baseline + `nixtop.shell` / `nixtop.desktop.enable` / dev flags |
| `core/greetd.nix` | `nixtop.greetd.{enable,greeter}` selector, asserts exactly one greeter |
| `core/plymouth.nix` | Plymouth `blahaj` splash |
| `core/nix-ld.nix` | `nix-ld` libraries for non-Nix binaries |
| `core/podman.nix` | Podman + compositor tools |
| `core/zsh.nix`, `core/tmux.nix` | HM modules, referenced individually from `homeModules` |

Mango session registration is via the upstream flake `github:mangowm/mango` (`programs.mango.enable` + `addLoginEntry = true` in `core/default.nix` when `nixtop.desktop.enable`), replacing the old `mango-session.nix` hand-rolled `.desktop`.

## Home Manager layers

### `modules/user/<name>/home.nix`

Thin profiles: `home.username`, `home.homeDirectory`, `nixtop.*.enable` switches, `home.packages` for one-offs, `~/Pictures/Wallpapers` symlink (alice+rose → `assets/wallpaper`), `home.stateVersion`, `programs.home-manager.enable`. `nixpak.nix` (alice, rose) is imported there.

Host → user matrix: `wonderland` = alice+lewis, `rabbit` = lewis, `garden` = rose.

### `modules/default.nix`

```nix
{
  nixosModules = [ ./core ./shell/noctalia/greeter.nix ./shell/quickshell/greeter.nix ];
  homeModules  = [ ./core/zsh.nix ./core/tmux.nix ./browsers ./conf ./emacs ./mango ./matugen ./sway ./shell ];
}
```

A concern directory may hold both kinds; the index decides placement.
Shell HM modules live under `modules/shell/` (`noctalia/`, `quickshell/`,
`jes/`); the greeters are NixOS modules imported separately above.

### HM control switches

| Prefix | Meaning |
|---|---|
| `nixtop.terminal.*` | zsh, tmux, foot (foot lives in `conf/` but keeps `nixtop.terminal.foot`) |
| `nixtop.apps.*` | `fetch`, `yazi`, `firefox-esr`, `floorp`, `emacs` |
| `nixtop.services.*` | `matugen` (plus future services) |
| `nixtop.shell` | `"noctalia"` \| `"quickshell"` \| `"jes"` \| `"none"` – the single switch for shell/Mango variant/theming default |
| `nixtop.theme.*` | `owner` / `apps.<app>` – who writes the generated config (matugen vs noctalia) |
| `nixtop.dev.*` | `liveEmacs` (default on), `liveMango`/`liveMatugen`/`liveQuickshell`/`liveSway`/`liveMako` (whole-dir, default off), `liveWaybar` (config file only — `style.css` is matugen-owned, default off), `~/Pictures/Wallpapers` (always-on, alice+rose) |

## Themes / shells

- **Mango**: `modules/mango/{config,settings,layout,rules,animations}.conf` (shared) + `variants/{noctalia,quickshell}/{appearance,keybinds,autostart}.conf` (shell-coupled). `default.nix` merges `shared + variants/${nixtop.shell}` into `~/.config/mango` as one directory (or one out-of-store symlink when `liveMango`). Generated colours go to `~/.local/state/nixtop/theme/mango.conf` (included from `config.conf`), not inside the repo checkout.
- **matugen**: `modules/matugen/default.nix` + templates (`noctalia` palette bridge, `jes`, `mango`, `sway`, `waybar`, `fuzzel`, `mako`, `quickshell`, `foot`, `gtk3/4`, `bat`, `starship`, `fastfetch`, `yazi`, `emacs`, `papirus-icons`). Registry is one Nix attrset → `config.toml` generated at build time. `nixtop-theme <image>` runs `matugen image <image>` + nudges Noctalia (`noctalia msg reload`) + Mango (`mmsg dispatch reload_config`).
- **Out-of-store symlink budget**: default no symlinks; one symlink per live flag; generated files in `~/.local/state` / dedicated runtime dir, never inside a symlinked dir. A path matugen writes must never also be HM-managed (a store symlink is read-only and the whole run fails): `waybar/style.css` is seeded once as a writable copy and then matugen-owned; `mako`/`foot`/`fuzzel` static configs `include=` a generated file that lives outside the managed dir.
- **Noctalia** (`modules/shell/noctalia/`): `default.nix` (HM, follows `nixtop.shell`), `greeter.nix` (NixOS, `programs.noctalia-greeter`). Palette bridge: matugen writes `~/.config/noctalia/palettes/nixtop.json`, Noctalia reads `source = "custom"`, `custom_palette = "nixtop"`. Owns mango colors + starship via `theme.templates.user.{mango,starship}`.
- **Quickshell** (`modules/shell/quickshell/`): own `nixtop-shell` config at `shell/` (`~/.config/nixtop-shell`, env `NIXTOP_SHELL_*`, bin `nixtop-shell`/`nixtop-shell-greeter`). `package.nix` (symlinkJoin + makeWrapper) builds the wrapper + Go IPC daemons (`ipc/`), `greeter.nix` supplies the `nixtop.greetd.greeter == "quickshell"` command.
- **JES** (`modules/shell/jes/`): vendored Just Enough Shell fork (see `UPSTREAM`). QML at `shell/` installs to `~/.local/JES/quickshell`, static config at `config/` to `~/.config/JES`, colors via the matugen `jes` template. `package.nix` wraps `qs` as `jes-qs`; `sway/keybinds.conf` is included by the sway variant.

## Rebuild workflow

1. Pick nearest control point from the table above.
2. If you added a module, add it to `modules/default.nix`.
3. `nix fmt` (or `nix fmt` via `formatter`).
4. `nix flake check --no-build` and `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` – build first, never push or run `disko` against real disks while iterating.
5. `nixos-rebuild switch --flake .#<host>`.

To debug evaluation: `nix repl` on the flake or `--show-trace`.
