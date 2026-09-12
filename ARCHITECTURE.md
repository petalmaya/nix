# How this configuration is wired

This file is the map for the repository. The short version is:

```text
flake.nix
├── chooses a host
├── imports that host's hardware file and configuration
├── imports ./modules/nixos for shared system modules
└── adds Home Manager and imports ./modules/home
    └── each user's home.nix turns individual modules on or off
```

The important rule is: **a file does nothing just because it exists in the repository.**
A Nix file must be imported, and a module with an `enable` option usually must also be enabled by a host or user.

## Start here

| Want to change... | Edit... |
| --- | --- |
| Which machines can be built | `flake.nix`, `nixosConfigurations` |
| Which user is installed on a machine | `flake.nix`, the `hmUsers` argument to `mkHost` |
| Machine-specific settings | `hosts/<machine>/configuration.nix` |
| Disk layout | `hosts/<machine>/disko.nix` or the generated hardware file |
| Shared operating-system behavior | `hosts/common/default.nix` |
| A system module's implementation | `modules/nixos/<name>.nix` |
| Shared Home Manager module wiring | `modules/home/default.nix` |
| What Alice or Lewis gets | `users/<user>/home.nix` |
| A Home Manager module's implementation | `modules/home/apps`, `services`, `terminal`, or `themes` |
| Theme files and shell configuration | `modules/home/themes/<theme>` |
| Flake inputs and pinned versions | `flake.nix` and `flake.lock` |
| Encrypted values | `secrets/` and `.sops.yaml` |

## What happens during a rebuild

For example:

```sh
sudo nixos-rebuild switch --flake .#wonderland
```

1. `flake.nix` calls `mkHost "x86_64-linux" "wonderland" ...`.
2. NixOS imports `hosts/wonderland/hardware-configuration.nix`.
   This is generated hardware detection and is intentionally separate from hand-written settings.
3. NixOS imports `hosts/wonderland/configuration.nix`.
   That file imports `hosts/common/default.nix`, `hosts/common/home-wifi.nix`, and `disko.nix`.
4. NixOS imports `modules/nixos/default.nix`.
   This is the explicit index of the custom system modules. It is imported once by `flake.nix`.
5. The flake adds third-party NixOS modules such as Home Manager, sops-nix, disko, Flatpak, and the greeter module.
6. Home Manager receives Alice's and Lewis's `home.nix` files.
7. `modules/home/default.nix` makes all custom Home Manager modules available.
8. Each user's `nixtop.*.enable = true` settings decide what is actually active.

`rabbit` follows the same path. It has different hardware and host settings, but shares the common system policy and both users' home configurations.

## System-level layers

### `flake.nix`

This is the entry point and composition layer. It does not contain most of the actual system policy. It mainly:

- pins external inputs;
- creates the `wonderland` and `rabbit` system outputs;
- passes `inputs` and an unstable package set into modules;
- imports each host's hardware and configuration;
- imports the custom NixOS module index;
- configures Home Manager and the shared Home Manager modules.

### `hosts/<name>/`

A host directory answers: **what is different about this physical machine?**

- `hardware-configuration.nix`: generated hardware and filesystem facts. Avoid hand-editing unless you know why.
- `configuration.nix`: hostname, firmware, GPU, Bluetooth, locale, special boot behavior, and host-specific toggles.
- `disko.nix`: declarative disk layout. Only `wonderland` currently has one.

The hardware file is imported by `flake.nix`, not by the host's `configuration.nix`. This keeps the host entry point from importing the same file twice.

### `hosts/common/`

This is the shared operating-system policy:

- bootloader, swap, zram, kernel settings, timezone, networking, SSH, users, and secrets;
- the `nixtop.desktop.enable` switch;
- desktop hardware and services when that switch is on;
- shared Wi-Fi secret activation.

The desktop switch currently enables Mango, the Teakettler greetd session, Plymouth, PipeWire, graphics, fonts, Steam support, Flatpak, and related desktop services.

### `modules/nixos/`

`modules/nixos/default.nix` is the list to check when asking “which custom system modules exist?”

| File | Controls |
| --- | --- |
| `cachix.nix` | Imports every cache definition in `modules/nixos/cachix/` and adds the NixOS cache |
| `mango-session.nix` | Adds Mango as a display-manager session when `nixtop.mango-session.enable` is on |
| `nagare-greeter.nix` | Optional Nagare greeter module; not enabled by the current desktop setup |
| `nix-ld.nix` | Enables libraries for running some prebuilt non-Nix binaries |
| `noctalia-greeter.nix` | Optional Noctalia greeter module; explicitly disabled by the desktop setup |
| `plymouth.nix` | Enables the Plymouth boot splash when `nixtop.plymouth.enable` is on |
| `podman.nix` | Enables Podman and adds container tools; currently always imported and therefore active |
| `teakettler-greeter.nix` | Provides the Teakettler greetd session used by the desktop setup |
| `tor.nix` | Provides an optional Tor + nginx service through `nixtop.tor.enable` |

## Home Manager layers

### `users/<name>/home.nix`

These are the user profiles. They are the most useful files for day-to-day changes.

The `nixtop` block is the control panel:

```nix
nixtop = {
  themes.teakettler.enable = true;
  terminal.foot.enable = true;
  apps.firefox-esr.enable = true;
  services.flatpak.enable = true;
};
```

The module implementation lives elsewhere, but the switch is normally changed here.

Packages that do not need their own reusable module are also declared directly in `home.packages` in the user file. That is why a package can be present even when there is no corresponding `modules/home/apps/<package>` file.

### `modules/home/default.nix`

This is the Home Manager module index. It makes the app, service, terminal, and theme modules available to every user. It does **not** turn them on.

If a new Home Manager module is not listed here, its `enable` option will not exist in a user profile.

### Home Manager control switches

| Prefix | Location | Meaning |
| --- | --- | --- |
| `nixtop.apps.*` | `modules/home/apps` | User applications and app-specific configuration |
| `nixtop.services.*` | `modules/home/services` | User services and generated configuration |
| `nixtop.terminal.*` | `modules/home/terminal` | Terminal emulator and shell tools |
| `nixtop.themes.*` | `modules/home/themes` | Desktop theme, compositor, shell, and related files |

A module can also import another module. For example, the Teakettler and Manguru themes import their Mango configuration, and the Nagare and Noctaniri themes import Niri configuration.

### Package groups and per-package exclusions

The reusable package groups live in `modules/home/apps/*.nix` and follow the same shape as `gaming.nix`:

| Switch | Group |
| --- | --- |
| `nixtop.apps.communication` | browsers/tools for messaging, sharing, and chat |
| `nixtop.apps.creative` | creative and design applications |
| `nixtop.apps.desktop` | desktop utilities, screenshots, input, and appearance tools |
| `nixtop.apps.fetch` | Fastfetch and Hyfetch configuration |
| `nixtop.apps.gaming` | Wine, game engines, launchers, Steam tools, and games |
| `nixtop.apps.launchers` | application launchers such as Fuzzel |
| `nixtop.apps.media` | media players, audio tools, and media conversion tools |
| `nixtop.apps.tools` | command-line tools and general utilities |

A group has two jobs:

1. `enable = true` turns on the category.
2. `exclude = [ ... ]` removes named packages from that category.

For example, Lewis can use most of gaming without installing Wine or OpenTTD:

```nix
nixtop.apps.gaming = {
  enable = true;
  exclude = [ "wine" "openttd" ];
};
```

The names in `exclude` are the names shown in the group's package map, not necessarily display names. To see exactly what can be excluded, open the relevant module, for example `modules/home/apps/gaming.nix`.

This is preferable to copying a package list into every user profile: the category owns the list, while the profile only chooses the category and its exceptions. If a package is truly a one-off, keep it in that user's `home.packages` instead.

## Turning off an option that another module turned on

There are two different situations, and they should not be confused:

### Excluding one package from a package group

Use the group's `exclude` option. This prevents the package from being added to `home.packages`:

```nix
nixtop.apps.gaming = {
  enable = true;
  exclude = [ "wine" "openttd" ];
};
```

This does not disable the gaming module. The other gaming packages still appear.

### Overriding a real Nix/Home Manager option

Sometimes a theme or shared module sets an option to `true`, and you need to win the module merge. Use `lib.mkForce` for that option:

```nix
{ lib, ... }:
{
  services.mako.enable = lib.mkForce false;
}
```

That is what the Teakettler, Nagare, and Manguru themes do: their QuickShell shell provides its own notification server, so they force Mako off even if a user enabled `nixtop.services.mako.enable`.

Use `mkForce` only for option conflicts. It is not needed for package exclusions, and it does not remove a package that another module put in `home.packages`. For a package conflict, find the module adding the package and use its `exclude` option, or change that module's package list.

`lib.mkForce` wins over normal assignments and `lib.mkDefault`, but another `lib.mkForce` at the same priority can still create a conflict. If you need to understand why a value won, search for every assignment to that option before adding another force.

## Themes: the part with the most hidden coupling

The selected theme is normally set in a user file by enabling exactly one theme:

```nix
nixtop.themes.teakettler.enable = true;
```

`modules/home/themes/active.nix` calculates `nixtop.activeTheme` from the enabled theme flags. The order there is a fallback priority, not a good way to select multiple themes. Treat themes as mutually exclusive.

`activeTheme` is used by modules such as Foot to choose theme-specific configuration. The theme modules themselves control compositor and shell files. Matugen is separate: it generates colors and application configuration through `nixtop.services.matugen`, rather than being selected by `activeTheme`.

Current user selection:

- Alice: Teakettler, Foot, Zsh, Zellij, the communication, creative, desktop, fetch, gaming, media, and tools groups, Firefox ESR, Emacs, Yazi, Spicetify, Mako, Flatpak, and MPD.
- Lewis: Teakettler, Foot, the communication, desktop, fetch, launcher, media, tools, and gaming groups, Firefox ESR, and Flatpak. Lewis excludes Wine and OpenTTD from gaming, plus a few less useful packages from the other groups.
- Both users get the same module library, but their enabled switches, exclusions, and one-off packages differ.

## Things that are easy to mistake for something else

- `modules/home/themes/teakettler/quickshell` and `modules/home/themes/nagare/quickshell` are source trees used by the theme packages. They are not separate Nix modules.
- `modules/home/services/matugen/templates` contains template inputs. The Matugen module decides which templates are enabled.
- `modules/nixos/cachix/` contains small cache modules discovered automatically by `cachix.nix`.
- `flake.lock` is generated state. Change input URLs in `flake.nix`; update the lock file with the normal flake update workflow.
- `secrets/secrets.yaml` is intentionally not a normal source file. sops-nix decrypts it during system activation.
- The out-of-store symlinks used by the Nagare and Teakettler themes point back into this checkout so QML/config edits can be tested without rebuilding every time. The `repoPath` options control those paths.

## A practical change workflow

1. Decide whether the change belongs to the machine, operating system, user, or a reusable module.
2. Change the nearest control point listed in the tables above.
3. If you created a new module, add it to `modules/nixos/default.nix` or `modules/home/default.nix`.
4. Check the affected host or user with `nix flake check`.
5. Only then rebuild a machine with `nixos-rebuild`.

If you are unsure what controls a setting, search for the option name first:

```sh
rg 'nixtop\.|imports|programs\.|services\.'
```
