# EWM tools (Home Manager side). Per-user, independent of nixtop.shell.
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  cfg = config.nixtop.ewm;
  # From EWM's own nixpkgs set.
  ewmElisp = inputs.ewm.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.nixtop.ewm.enable = lib.mkEnableOption "EWM Emacs overlay and tools for this user (extra pattern, keeps nixtop.shell)";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = osConfig != null && (osConfig.nixtop.ewm.enable or false);
        message = "nixtop.ewm.enable needs nixtop.ewm.enable on the host as well (hosts/<name>/default.nix)";
      }
    ];

    home.packages = with pkgs; [
      wl-clipboard
      brightnessctl
      swaybg
      mako
      libnotify
      ewmElisp
    ];

    # Gated on $WAYLAND_DISPLAY, safe to source unconditionally.
    programs.zsh.initContent = lib.mkAfter ''
      if [ -f "${ewmElisp}/etc/emacs-ewm.zsh" ]; then
        source "${ewmElisp}/etc/emacs-ewm.zsh"
      fi
    '';
  };
}
