{ config, pkgs, lib, ... }:

{
  options.nixtop.terminal.zsh.enable = lib.mkEnableOption "Zsh configuration with extras";

  config = lib.mkIf config.nixtop.terminal.zsh.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };
    # matugen owns starship.toml on kurukuru/manguru hosts
    xdg.configFile."starship.toml" = lib.mkIf (!(config.nixtop.themes.kurukuru.enable or false) && !(config.nixtop.themes.manguru.enable or false)) {
      source = ./starship.toml;
    };

    programs.zsh = {
      enable            = true;
      enableCompletion  = true;
      autosuggestion.enable        = true;
      syntaxHighlighting.enable    = false;
      historySubstringSearch.enable = true;

      history = {
        size          = 50000;
        save          = 50000;
        ignoreDups    = true;
        ignoreSpace   = true;
        expireDuplicatesFirst = true;
        share         = true;
      };

      plugins = [
        {
          name = "fast-syntax-highlighting";
          src  = pkgs.zsh-fast-syntax-highlighting;
          file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
        }
        {
          name = "zsh-nix-shell";
          src  = pkgs.zsh-nix-shell;
          file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
        }
        {
          name = "zsh-autopair";
          src  = pkgs.zsh-autopair;
          file = "share/zsh/zsh-autopair/autopair.zsh";
        }
      ];

      initContent = builtins.readFile ./zshrc;

      shellAliases = {
        nixsw = "sudo nixos-rebuild switch --flake .#${if config ? osConfig then config.osConfig.networking.hostName else "wonderland"}";
        nixup = "nix flake update";

        ls  = "ls --color=auto";
        ll  = "ls -lah --color=auto";
        ".." = "cd ..";
        "..." = "cd ../..";
        cat = "bat";
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

    # gruvbox dark
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
