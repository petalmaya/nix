{ config, pkgs, lib, ... }:

{
  # ── Starship prompt (gruvbox-rainbow) ──────────────────────────────────────
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = ''
        [](color_orange)\
        $os\
        $username\
        [](bg:color_yellow fg:color_orange)\
        $directory\
        [](fg:color_yellow bg:color_aqua)\
        $git_branch\
        $git_status\
        [](fg:color_aqua bg:color_blue)\
        $c\
        $cpp\
        $rust\
        $golang\
        $nodejs\
        $bun\
        $php\
        $java\
        $kotlin\
        $haskell\
        $python\
        [](fg:color_blue bg:color_bg3)\
        $docker_context\
        $conda\
        $pixi\
        [](fg:color_bg3 bg:color_bg1)\
        $time\
        [ ](fg:color_bg1)\
        $line_break$character'';

      palette = "gruvbox_dark";

      "palettes.gruvbox_dark" = {
        color_fg0    = "#fbf1c7";
        color_bg1    = "#3c3836";
        color_bg3    = "#665c54";
        color_blue   = "#458588";
        color_aqua   = "#689d6a";
        color_green  = "#98971a";
        color_orange = "#d65d0e";
        color_purple = "#b16286";
        color_red    = "#cc241d";
        color_yellow = "#d79921";
      };

      # ── OS icon ─────────────────────────────────────────────────────────────
      os = {
        disabled = false;
        style    = "bg:color_orange fg:color_fg0";
      };

      "os.symbols" = {
        NixOS            = "";
        Linux            = "󰌽";
        Windows          = "󰍲";
        Macos            = "󰀵";
        Ubuntu           = "󰕈";
        Arch             = "󰣇";
        Artix            = "󰣇";
        Debian           = "󰣚";
        Fedora           = "󰣛";
        Gentoo           = "󰣨";
        Manjaro          = "";
        Mint             = "󰣭";
        EndeavourOS      = "";
        Pop              = "";
        Raspbian         = "󰐿";
        SUSE             = "";
        Alpine           = "";
        Amazon           = "";
        Android          = "";
        AOSC             = "";
        CentOS           = "";
        Redhat           = "󱄛";
        RedHatEnterprise = "󱄛";
      };

      # ── User ────────────────────────────────────────────────────────────────
      username = {
        show_always = true;
        style_user  = "bg:color_orange fg:color_fg0";
        style_root  = "bg:color_orange fg:color_fg0";
        format      = "[ $user ]($style)";
      };

      # ── Directory ──────────────────────────────────────────────────────────
      directory = {
        style             = "fg:color_fg0 bg:color_yellow";
        format            = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      "directory.substitutions" = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music"     = "󰝚 ";
        "Pictures"  = " ";
        "Developer" = "󰲋 ";
      };

      # ── Git ────────────────────────────────────────────────────────────────
      git_branch = {
        symbol = "";
        style  = "bg:color_aqua";
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style  = "bg:color_aqua";
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      # ── Languages ───────────────────────────────────────────────────────────
      nodejs = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      bun = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      c = {
        symbol = " ";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      cpp = {
        symbol = " ";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      rust = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      golang = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      php = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      java = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      kotlin = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      haskell = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      python = {
        symbol = "";
        style  = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      # ── Containers / environments ────────────────────────────────────────────
      docker_context = {
        symbol = "";
        style  = "bg:color_bg3";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };
      conda = {
        style  = "bg:color_bg3";
        format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)";
      };
      pixi = {
        style  = "bg:color_bg3";
        format = "[[ $symbol( $version)( $environment) ](fg:color_fg0 bg:color_bg3)]($style)";
      };

      # ── Time ────────────────────────────────────────────────────────────────
      time = {
        disabled    = false;
        time_format = "%R";
        style       = "bg:color_bg1";
        format      = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      # ── Prompt character ────────────────────────────────────────────────────
      line_break.disabled = false;

      character = {
        disabled                  = false;
        success_symbol            = "[](bold fg:color_green)";
        error_symbol              = "[](bold fg:color_red)";
        vimcmd_symbol             = "[](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
        vimcmd_replace_symbol     = "[](bold fg:color_purple)";
        vimcmd_visual_symbol      = "[](bold fg:color_yellow)";
      };

      # ── cmd duration ────────────────────────────────────────────────────────
      cmd_duration = {
        min_time           = 2000;
        format             = "took [$duration]($style) ";
        style              = "bold color_yellow";
        show_notifications = false;
      };
    };
  };

  # ── Zsh ────────────────────────────────────────────────────────────────────
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

    initContent = ''
      # ── Completion tweaks ───────────────────────────────────────────────────
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*:descriptions' format '%B%d%b'

      # ── Key bindings ────────────────────────────────────────────────────────
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # ── Options ─────────────────────────────────────────────────────────────
      setopt AUTO_CD
      setopt CORRECT
      setopt NO_BEEP

      # ── Git aliases ─────────────────────────────────────────────────────────
      alias gs='git status -sb'
      alias ga='git add'
      alias gc='git commit'
      alias gp='git push'
      alias gl='git log --oneline --graph --decorate --all'
      alias gd='git diff'
      alias gco='git checkout'
      alias gcb='git checkout -b'
      alias gpl='git pull --rebase'
    '';

    shellAliases = {
      # Nix
      nixsw = "sudo nixos-rebuild switch --flake .#wonderland";
      nixup = "nix flake update";

      # Convenience
      ls  = "ls --color=auto";
      ll  = "ls -lah --color=auto";
      ".." = "cd ..";
      "..." = "cd ../..";
      cat = "bat";
    };
  };

  # ── Zoxide (smart cd) ──────────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── Fzf – gruvbox dark colours ─────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--color=bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#928374"
      "--color=fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934"
      "--color=marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934"
    ];
  };

  # ── bat (pretty cat) ──────────────────────────────────────────────────────
  programs.bat = {
    enable = true;
    config.theme = "gruvbox-dark";
  };
}
