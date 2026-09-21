# EWM tools (Home Manager side). Per-user, independent of nixtop.shell.
# The elisp overlay (lisp/init-ewm.el) loads regardless but stays inert
# without ewm.el; this module only adds packages plus the zsh hook.
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
  # ewm.el + libewm_core.so + shell hooks, from EWM's own nixpkgs set.
  ewmElisp =
    inputs.ewm.packages.${pkgs.stdenv.hostPlatform.system}.default or null;
in
{
  options.nixtop.ewm.enable = lib.mkEnableOption "EWM Emacs overlay and tools for this user (extra pattern, keeps nixtop.shell)";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = ewmElisp != null;
        message = "nixtop.ewm needs inputs.ewm.packages for ${pkgs.stdenv.hostPlatform.system}";
      }
      {
        # Interactive Emacs is the session package (see modules/emacs),
        # so the host side must be on or ewm.el is missing.
        assertion = osConfig != null && (osConfig.nixtop.ewm.enable or false);
        message = "nixtop.ewm.enable needs nixtop.ewm.enable on the host as well (hosts/<name>/default.nix)";
      }
    ];

    home.packages =
      with pkgs;
      [
        wl-clipboard
        brightnessctl
        swaybg
      ]
      ++ lib.optionals (ewmElisp != null) [
        # For etc/emacs-ewm.zsh below; the load-path comes from modules/emacs.
        ewmElisp
      ];

    # Reports $PWD to the surface buffer via emacsclient. Gated on
    # $WAYLAND_DISPLAY, so safe to source unconditionally.
    programs.zsh.initContent = lib.mkIf (ewmElisp != null) (
      lib.mkAfter ''
        if [ -f "${ewmElisp}/etc/emacs-ewm.zsh" ]; then
          source "${ewmElisp}/etc/emacs-ewm.zsh"
        fi
      ''
    );
  };
}
