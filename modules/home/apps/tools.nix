{ config, lib, pkgs, unstable-pkgs, ... }:

let
  cfg = config.nixtop.apps.tools;
  packages = {
    chafa = pkgs.chafa;
    libsixel = pkgs.libsixel;
    ripgrep = pkgs.ripgrep;
    btop = pkgs.btop;
    tree = pkgs.tree;
    "bitwarden-cli" = pkgs.bitwarden-cli;
    git = pkgs.git;
    unzip = pkgs.unzip;
    p7zip = pkgs.p7zip;
    wget = pkgs.wget;
    curl = pkgs.curl;
    age = pkgs.age;
    sops = pkgs.sops;
    stack = pkgs.stack;
    "ani-cli" = unstable-pkgs.ani-cli;
    "yt-dlp" = unstable-pkgs.yt-dlp;
  };

  selectedPackages = lib.filterAttrs
    (name: _: !builtins.elem name cfg.exclude)
    packages;
in
{
  options.nixtop.apps.tools = {
    enable = lib.mkEnableOption "Command-line tools and utilities";
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Package names to leave out of this group.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.attrValues selectedPackages;
  };
}
