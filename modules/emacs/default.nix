{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.apps.emacs;
  emacsPkg = pkgs.emacs-pgtk;
  externalTools = with pkgs; [
    ripgrep
    fd
    git
    nodejs_22
    typescript-language-server
    bash-language-server
    vscode-langservers-extracted
    nil
    nixpkgs-fmt
    python3
    pyright
    rust-analyzer
    rustc
    cargo
    qt6.qtdeclarative
    aspell
    aspellDicts.en
    poppler-utils
    imagemagick
    sqlite
    pandoc
    shellcheck
    jq
    nerd-fonts.jetbrains-mono
    jetbrains-mono
  ];
in
{
  options.nixtop.apps.emacs.enable = lib.mkEnableOption "Emacs (pinaceae-emacs config)";
  options.nixtop.apps.emacs.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = "Where this repo is cloned, used for the ~/.config/emacs symlink.";
  };

  config = lib.mkIf cfg.enable (let
    liveEmacs = if config ? osConfig then config.osConfig.nixtop.dev.liveEmacs else config.nixtop.dev.liveEmacs or true;
  in {
    home.packages = [ emacsPkg ] ++ externalTools;

    # Live-editable directory (D23, §8.4). Flag defaults on.
    xdg.configFile."emacs" = if liveEmacs then {
      source = config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/emacs/emacs";
    } else {
      source = ./emacs;
      recursive = true;
    };
  });
}
