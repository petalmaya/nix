{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  cfg = config.nixtop.apps.emacs;
  ewmSysOn = if osConfig != null then osConfig.nixtop.ewm.enable or false else false;
  ewmOn = config.nixtop.ewm.enable or false;
  emacsPkg = if ewmOn && ewmSysOn then osConfig.programs.ewm.emacsPackage else pkgs.emacs-pgtk;
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
  options.nixtop.apps.emacs.enable = lib.mkEnableOption "Emacs (Pinaceae Emacs config)";
  options.nixtop.apps.emacs.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = "Where this repo is cloned, used for the ~/.config/emacs symlink.";
  };

  config = lib.mkIf cfg.enable (
    let
      liveEmacs =
        if osConfig != null then
          osConfig.nixtop.dev.liveEmacs or true
        else
          config.nixtop.dev.liveEmacs or true;
    in
    {
      home.packages = [ emacsPkg ] ++ externalTools;

      # Live-editable directory; flag defaults on.
      xdg.configFile."emacs" =
        if liveEmacs then
          {
            source = config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/emacs/emacs";
          }
        else
          {
            source = ./emacs;
            recursive = true;
          };
    }
  );
}
