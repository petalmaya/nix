{ config, lib, pkgs, inputs, ... }:
let
  shell = if config ? osConfig then config.osConfig.nixtop.shell else config.nixtop.shell or "noctalia";
  mangoSrc = ./.;
  variantDir = ./variants/${shell};

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
          default = [ "gtk" "gnome" ];
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

    (lib.mkIf (!((if config ? osConfig then config.osConfig.nixtop.dev.liveMango else config.nixtop.dev.liveMango or false))) {
      # store-built mango config – one directory, not 8 symlinks (§8.4)
      xdg.configFile."mango".source = mangoConfig;
      xdg.configFile."mango".recursive = true;
    })

    (lib.mkIf (if config ? osConfig then config.osConfig.nixtop.dev.liveMango else config.nixtop.dev.liveMango or false) {
      # live-editable whole directory (dev only)
      xdg.configFile."mango".source = config.lib.file.mkOutOfStoreSymlink livePath;
      # variant files still need to be the selected shell's version – liveMango
      # points at the shared directory, so the variant switch doesn't work live.
      # Documented trade-off: with liveMango on, you edit the variant file
      # directly or flip the shell and rebuild.
      home.activation.warnLiveMangoVariant = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo "liveMango on: Mango variant is ${shell} (edit modules/mango/variants/${shell}/ directly)" >&2
      '';
    })

    # When liveMango is off, also generate the theme file at runtime path (managed by matugen)
    # The file at ~/.local/state/nixtop/theme/mango.conf is written by the matugen bridge – ensure the dir exists
    {
      home.activation.ensureMangoThemeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state/nixtop/theme"
        $DRY_RUN_CMD [ -e "$HOME/.local/state/nixtop/theme/mango.conf" ] || $DRY_RUN_CMD touch "$HOME/.local/state/nixtop/theme/mango.conf"
      '';
    }
  ];
}
