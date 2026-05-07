{ config, pkgs, lib, ... }:

{
  # ── Starship prompt (darkblood style) ─────────────────────────────────────
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;

      # Line 1: ┏[user][git][⚡ if root][x reason if error]
      # Line 2: ┖[full path]>
      # Note: double-quoted string so \n = real newline, \\ = backslash
      format = "┏$username$git_branch$sudo$status\n┖$directory> ";

      # ── User ──────────────────────────────────────────────────────────────
      username = {
        show_always = true;
        style_user  = "#e0def4";
        style_root  = "#e0def4";
        format      = "[\\[](bold #ea9a97)[$user]($style)[\\]](bold #ea9a97)";
      };

      # ── Directory ─────────────────────────────────────────────────────────
      directory = {
        style             = "#e0def4";
        format            = "[\\[](bold #ea9a97)[$path]($style)[\\]](bold #ea9a97)";
        truncation_length = 0;
        truncate_to_repo  = false;
      };

      # ── Git branch ────────────────────────────────────────────────────────
      git_branch = {
        symbol = "";
        style  = "#e0def4";
        format = "[\\[](bold #ea9a97)[$symbol $branch]($style)[\\]](bold #ea9a97)";
      };

      git_status = {
        disabled = true;
      };

      # ── Root indicator (⚡) ───────────────────────────────────────────────
      sudo = {
        disabled = false;
        symbol   = "⚡";
        style    = "#e0def4";
        format   = "[\\[](bold #ea9a97)[$symbol]($style)[\\]](bold #ea9a97)";
      };

      # ── Exit status ───────────────────────────────────────────────────────
      status = {
        disabled = false;
        symbol   = "x";
        style    = "#e0def4";
        format   = "[\\[](bold #ea9a97)[x$common_meaning]($style)[\\]](bold #ea9a97)";
      };

      # ── No separate character module (> is baked into format) ─────────────
      character = {
        disabled = true;
      };

      line_break.disabled = true;

      # ── cmd duration ──────────────────────────────────────────────────────
      cmd_duration = {
        min_time = 2000;
        format   = "took [$duration]($style) ";
        style    = "bold #ea9a97";
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
