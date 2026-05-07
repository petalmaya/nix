{ config, pkgs, lib, ... }:

{
  # ── Starship prompt ─────────────
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # overall feel
      add_newline = false;
      scan_timeout = 10;
      command_timeout = 500;

      format = "$username$directory$git_branch$git_state$git_status$cmd_duration$line_break$character";

      # directory
      directory = {
        truncation_length = 3;
        truncate_to_repo  = true;
        style             = "bold cyan";
      };

      # git <2
      git_branch = {
        symbol = " ";
        style  = "bold purple";
      };
      git_status = {
        ahead    = "⇡$count";
        behind   = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        modified = "!$count";
        staged   = "+$count";
        untracked= "?$count";
        stashed  = "≡";
        style    = "bold red";
      };
      git_state = {
        style = "bold yellow";
      };

      # prompt character
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };

      # cmd duration – only shown when > 2 s
      cmd_duration = {
        min_time           = 2000;
        format             = "⏱ [$duration]($style) ";
        style              = "bold yellow";
        show_notifications = false;
      };

      # hide username when not root / not SSH
      username = {
        show_always = false;
        format      = "[$user]($style) in ";
        style_user  = "bold green";
        style_root  = "bold red";
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
      share         = true;           # share history across sessions
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
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*:descriptions' format '%B%d%b'

      # ── Key bindings ────────────────────────────────────────────────────────
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # ── Options ─────────────────────────────────────────────────────────────
      setopt AUTO_CD              # type dir name to cd into it
      setopt CORRECT              # suggest corrections for mistyped commands
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

  # ── Fzf (fuzzy finder) ────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── bat (pretty cat) ──────────────────────────────────────────────────────
  programs.bat = {
    enable = true;
    config.theme = "base16";
  };
}
