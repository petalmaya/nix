{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  # Per-user shell (modules/shell): host default, overridable per user.
  shell = config.nixtop.shell;
  shellEnabled = shell == "jes";
  cfg = config.nixtop.jes;

  jesPkg = pkgs.callPackage ./package.nix { };

  # Upstream drops jes-cli in ~/.local/bin, which is not on sway's exec PATH
  # (variant autostart + these keybinds call it bare). Package it instead so
  # it resolves via ~/.nix-profile/bin like every other sway exec target.
  # Two more upstream-isms are rewritten at package time (vendored file stays
  # pristine): bare `qs` becomes the jes-qs wrapper (it carries the QML import
  # paths, without which the shell dies on `import JES.Helpers`), and the
  # shell dir moves from `-c` to `-p` — in quickshell 0.3 `-c` takes a config
  # *name*, not a path, so the daemon exited with "no such configuration".
  jesCli = pkgs.writeShellScriptBin "jes-cli" (
    builtins.replaceStrings
      [
        "qs -c $HOME/.local/JES/quickshell ipc call root"
        "qs -c $HOME/.local/JES/quickshell log"
        "qs -d -c $HOME/.local/JES/quickshell"
        ''qs -d -c "$HOME/.local/JES/quickshell"''
      ]
      [
        "jes-qs ipc call root"
        "jes-qs log"
        "jes-qs -d -p $HOME/.local/JES/quickshell"
        ''jes-qs -d -p "$HOME/.local/JES/quickshell"''
      ]
      (builtins.readFile ./jes-cli)
  );
in
{
  options.nixtop.jes.enable = lib.mkOption {
    type = lib.types.bool;
    default = shellEnabled;
    description = "Enable Just Enough Shell (vendored fork). Follows nixtop.shell when auto.";
  };

  config = lib.mkIf (cfg.enable && shellEnabled) {
    home.packages = [
      jesPkg
      jesCli
      pkgs.quickshell
      pkgs.taplo # shell.qml converts config.toml -> JES_config.json via taplo
      pkgs.jq
      pkgs.nerd-fonts.mononoki # JES default fontFamily
    ];

    # Shell source — same paths upstream expects (~/.local/JES/quickshell)
    home.file.".local/JES/quickshell".source = ./shell;

    # JES config — static files; colors come from matugen (JES_colors.json)
    xdg.configFile."JES/config.toml".source = ./config/config.toml;
    xdg.configFile."JES/wallpaper.toml".source = ./config/wallpaper.toml;
    xdg.configFile."JES/waypoints.json".source = ./config/waypoints.json;
    xdg.configFile."JES/base16.json".source = ./config/base16.json;

    home.activation.ensureJesDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.cache/JES" "$HOME/.local/state" "$HOME/Screenshots"
      $DRY_RUN_CMD chmod +x "$HOME/.local/JES/quickshell/scripts/"* 2>/dev/null || true
      # seed JES colors so the shell has something before the first matugen run
      $DRY_RUN_CMD [ -e "$HOME/.local/state/JES_colors.json" ] || $DRY_RUN_CMD echo '{"background1":"#3f4944","background2":"#3b443f","background3":"#3c4540","backgroundAlt1":"#262c29","backgroundAlt2":"#262c29","font":"#b3ccbe","fontDark":"#1f352b","accent":"#8cd5b3","accent2":"#486657"}' > "$HOME/.local/state/JES_colors.json"
    '';

    assertions = [
      {
        assertion = !(config.nixtop.noctalia.enable or false);
        message = "nixtop.shell selects one shell – cannot enable jes with noctalia";
      }
      {
        assertion = !(config.nixtop.quickshell.enable or false);
        message = "nixtop.shell selects one shell – cannot enable jes with quickshell";
      }
    ];
  };
}
