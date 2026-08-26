# nix provides the binary + external tools, elpaca does everything else.
# ~/.config/emacs symlinks into this repo so editing lisp is a save, not a rebuild.
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
    qt6.qtdeclarative # qmlls, for editing this repo's quickshell/

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
in {
  options.nixtop.apps.emacs.enable = lib.mkEnableOption "Emacs (flutterice-emacs config)";
  options.nixtop.apps.emacs.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = ''
      Where this repo is cloned, used for the ~/.config/emacs symlink.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ emacsPkg ] ++ externalTools;

    home.file.".config/emacs".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/apps/emacs/emacs";
  };
}
