{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  shell = config.nixtop.shell;
  mangoSrc = ./.;
  # Noctalia and quickshell variants exist; other shells fall back to noctalia.
  variantDir = if shell == "quickshell" then ./variants/quickshell else ./variants/noctalia;
  liveMango =
    if osConfig != null then
      osConfig.nixtop.dev.liveMango or false
    else
      config.nixtop.dev.liveMango or false;

  # Build a merged Mango config directory (shared + shell variant)
  mangoConfig = pkgs.runCommand "mango-config-${shell}" { } ''
    mkdir -p $out
    cp ${mangoSrc}/config.conf $out/config.conf
    cp ${mangoSrc}/settings.conf $out/settings.conf
    cp ${mangoSrc}/layout.conf $out/layout.conf
    cp ${mangoSrc}/rules.conf $out/rules.conf
    cp ${mangoSrc}/animations.conf $out/animations.conf
    cp ${variantDir}/appearance.conf $out/appearance.conf
    cp ${variantDir}/keybinds.conf $out/keybinds.conf
    cp ${variantDir}/autostart.conf $out/autostart.conf
    # generate polkit.conf separately – store path, sourced from config.conf
    cat > $out/polkit.conf <<EOF
    exec-once=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    EOF
  '';

  # For liveMango the whole directory is symlinked to the repo (generated colors live elsewhere)
  livePath = "${config.home.homeDirectory}/nix/modules/mango";
in
{
  config = lib.mkMerge [
    {
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config.mango = {
          default = [
            "gtk"
            "gnome"
          ];
          "org.freedesktop.impl.portal.Access" = [ "gtk" ];
          "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        };
        extraPortals = [
          pkgs.gnome-keyring
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-wlr
        ];
      };

      home.packages = with pkgs; [
        swaybg
        jq
        swaylock
        grim
        slurp
      ];
    }

    (lib.mkIf (!liveMango) {
      xdg.configFile."mango".source = mangoConfig;
      xdg.configFile."mango".recursive = true;
    })

    (lib.mkIf liveMango {
      xdg.configFile."mango".source = config.lib.file.mkOutOfStoreSymlink livePath;
      # Live mode points at the shared dir, so the variant switch needs a rebuild.
      home.activation.warnLiveMangoVariant = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo "liveMango on: Mango variant is ${shell} (edit modules/mango/variants/${shell}/ directly)" >&2
      '';
    })

    # Matugen writes the theme file at this runtime path.
    {
      home.activation.ensureMangoThemeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state/nixtop/theme"
        $DRY_RUN_CMD [ -e "$HOME/.local/state/nixtop/theme/mango.conf" ] || $DRY_RUN_CMD touch "$HOME/.local/state/nixtop/theme/mango.conf"
      '';
    }
  ];
}
