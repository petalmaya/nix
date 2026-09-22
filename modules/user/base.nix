# Shared Home Manager baseline for all nixtop users.
# Import from modules/user/<name>/home.nix and keep only deltas there.
# (NixOS-side accounts – users.users.<name>, groups, shell – live in
# modules/core/default.nix for alice/lewis and hosts/garden/default.nix
# for rose; this file is HM-only.)
_: {
  nixtop = {
    terminal = {
      zsh.enable = true;
      tmux.enable = true;
      foot.enable = true;
    };
    apps = {
      fetch.enable = true;
      yazi.enable = true;
    };
    sway.enable = true;
  };

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    setSessionVariables = true;
  };
}
