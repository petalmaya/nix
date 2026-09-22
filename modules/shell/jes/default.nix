{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixtop.jes;
  active = config.nixtop.shell == "jes";

  jesPkg = pkgs.callPackage ./package.nix { };

  # Upstream drops jes-cli in ~/.local/bin, which is not on sway's exec PATH.
  # Package it so it resolves via ~/.nix-profile/bin. Two upstream
  # assumptions are rewritten at package time (vendored file stays pristine):
  # bare `qs` becomes the jes-qs wrapper (carries the QML import paths), and
  # the shell dir moves from `-c` to `-p` — in quickshell 0.3 `-c` takes a
  # config *name*, not a path.
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
    default = active;
    description = "Enable Just Enough Shell (vendored fork). Follows nixtop.shell when unset.";
  };

  config = lib.mkIf (cfg.enable && active) {
    home = {
      packages = [
        jesPkg
        jesCli
        pkgs.quickshell
        pkgs.taplo
        pkgs.jq
        pkgs.nerd-fonts.mononoki
      ];

      file.".local/JES/quickshell".source = ./shell;

      activation.ensureJesDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.cache/JES" "$HOME/.local/state" "$HOME/Screenshots"
        $DRY_RUN_CMD chmod +x "$HOME/.local/JES/quickshell/scripts/"* 2>/dev/null || true
        # Seed JES colors so the shell has something before the first matugen run.
        $DRY_RUN_CMD [ -e "$HOME/.local/state/JES_colors.json" ] || $DRY_RUN_CMD echo '{"background1":"#3f4944","background2":"#3b443f","background3":"#3c4540","backgroundAlt1":"#262c29","backgroundAlt2":"#262c29","font":"#b3ccbe","fontDark":"#1f352b","accent":"#8cd5b3","accent2":"#486657"}' > "$HOME/.local/state/JES_colors.json"
      '';
    };

    xdg.configFile = {
      "JES/config.toml".source = ./config/config.toml;
      "JES/wallpaper.toml".source = ./config/wallpaper.toml;
      "JES/waypoints.json".source = ./config/waypoints.json;
      "JES/base16.json".source = ./config/base16.json;
    };

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
