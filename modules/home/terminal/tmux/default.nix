{ pkgs, lib, config, ... }:

{
  options.nixtop.terminal.tmux.enable = lib.mkEnableOption "Tmux terminal multiplexer";

  config = lib.mkIf config.nixtop.terminal.tmux.enable {
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
      extraConfig = builtins.readFile ./tmux.conf;
    };

    home.file.".tmux.conf".text = ''
      source-file ${config.xdg.configHome}/tmux/tmux.conf
    '';
  };
}
