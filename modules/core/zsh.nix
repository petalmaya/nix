{ config, pkgs, lib, ... }:
let
  matugenOwnsStarship =
    (config.nixtop.services.matugen.enable or false)
    && (config.nixtop.services.matugen.templates.starship.enable or false);
in
{
  options.nixtop.terminal.zsh.enable = lib.mkEnableOption "Zsh configuration with extras";

  config = lib.mkIf config.nixtop.terminal.zsh.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };
    xdg.configFile."starship.toml" = lib.mkIf (!matugenOwnsStarship) {
      source = ./starship.toml;
    };

    programs.zsh = {
      enable = true;
      # updated behavior for 26.05 – XDG config dir instead of home
      dotDir = "${config.xdg.configHome}/zsh";
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = false;
      historySubstringSearch.enable = true;

      setOptions = [
        "AUTO_CD"
        "CORRECT"
        "NO_BEEP"
      ];

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
        share = true;
      };

      initContent = ''
        # Completion tweaks
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*:descriptions' format '%B%d%b'

        # Key bindings
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
      '';

      plugins = [
        {
          name = "fast-syntax-highlighting";
          src = pkgs.zsh-fast-syntax-highlighting;
          file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
        }
        {
          name = "zsh-nix-shell";
          src = pkgs.zsh-nix-shell;
          file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
        }
        {
          name = "zsh-autopair";
          src = pkgs.zsh-autopair;
          file = "share/zsh/zsh-autopair/autopair.zsh";
        }
      ];

      shellAliases = {
        nixsw = "sudo nixos-rebuild switch --flake .#${if config ? osConfig then config.osConfig.networking.hostName else "wonderland"}";
        nixup = "nix flake update";

        ls = "ls --color=auto";
        ll = "ls -lah --color=auto";
        ".." = "cd ..";
        "..." = "cd ../..";
        cat = "bat";

        gs = "git status -sb";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline --graph --decorate --all";
        gd = "git diff";
        gco = "git checkout";
        gcb = "git checkout -b";
        gpl = "git pull --rebase";
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--color=bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#928374"
        "--color=fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934"
        "--color=marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934"
      ];
    };

    programs.bat = {
      enable = true;
      config.theme = "gruvbox-dark";
    };
  };
}
