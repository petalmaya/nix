{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    plugins = [
      (pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "tmux-everforest";
        version = "unstable";
        src = pkgs.fetchFromGitHub {
          owner = "TanglingTreats";
          repo = "tmux-everforest";
          rev = "master";
          sha256 = "081iqmcgskfzb4qnlcnya9wppxsrzp7p3z0pxq72sx1y6lh2y2id";
        };
      })
    ];
    extraConfig = ''
      set -g @tmux-everforest 'dark-medium'
    '';
  };
}
