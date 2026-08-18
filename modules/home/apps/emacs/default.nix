# Emacs (pgtk build) + the vendored flutterice-emacs config in ./emacs.
# Nix only supplies the emacs binary and its external tools (ripgrep,
# language servers, etc) — elisp packages are Elpaca's job, not Nix's.
# Same out-of-store-symlink trick as themes/kurukuru: ~/.config/emacs
# points straight at this repo's ./emacs dir, so editing lisp is a
# save, not a rebuild.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.apps.emacs;
  emacsPkg = pkgs.emacs-pgtk;

  # Everything the config shells out to (see ./emacs/lisp/my-dev.el,
  # my-qml.el). None of it is elisp, so none of it goes through Elpaca.
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
    qt6.qtdeclarative # qmlls, for editing this same repo's quickshell/

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
      Path to your actual git checkout of this flake, used to symlink
      ~/.config/emacs -> ''${repoPath}/modules/home/apps/emacs/emacs.
      Only needs changing if you clone this repo somewhere other than
      ~/nix.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ emacsPkg ] ++ externalTools;

    # ./emacs/.gitignore already excludes elpaca/etc/var/custom.el, so
    # Elpaca's build output lands inside the live checkout without
    # getting committed.
    home.file.".config/emacs".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/apps/emacs/emacs";
  };
}
