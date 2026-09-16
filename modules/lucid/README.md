# Lucid (WIP, unconnected)

Planned: a quickshell-based shell for the **mango** compositor.

Status: option stub only. `nixtop.lucid.enable` exists, defaults off, and
installs nothing. It is deliberately **not** wired into `nixtop.shell`,
the sway/mango variants, matugen, or the mutual-exclusion guards.

To connect it when it starts cooking, follow `modules/jes/default.nix`:

1. Build/package the shell (wrapper + runtime deps).
2. Place its config (`xdg.configFile` / `home.file`).
3. Add a matugen template if it needs theme colors.
4. Add the compositor keybinds/autostart to the matching variant
   (`modules/mango/variants/`, `modules/sway` `variantConf`).
5. Add it to the shell-selector guards in `jes`/`noctalia`/`quickshell`.
