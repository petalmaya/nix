# NetBSD Mango Scaffold

This is a **scaffold only** – not imported by `modules/default.nix`, so it builds nothing by default.

* `default.nix` – HM module with `nixtop.netbsd.enable`. Enables `programs.waybar` + `programs.rofi` + placeholder Mango variant files.
* `waybar/` – `style.css` + `config.jsonc` (reference, HM generates the real config).
* `rofi/` – `config.rasi` (HM theme).
* `mango/` – `appearance.conf`, `keybinds.conf`, `autostart.conf` – copy into `modules/mango/variants/netbsd/` when you want it as a selectable Mango variant (`nixtop.shell = "netbsd"`), or keep as standalone.

To make it switchable:

1. Add `./netbsd` to `homeModules` in `modules/default.nix` (still off until `nixtop.netbsd.enable = true`).
2. Or copy `mango/*` into `modules/mango/variants/netbsd/` and extend `nixtop.shell` enum in `modules/core/default.nix` to include `"netbsd"` – then `nixtop.shell = "netbsd"` will pick `variants/netbsd/`.

Nothing in this folder touches `flake.nix` or host configs until you opt in.
