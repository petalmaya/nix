
# WARN: this file will get overwritten by $ cachix use <name>
#
# Dynamically imports every *.nix file found in the ./cachix/ directory so
# that running `cachix use <name>` (which drops a file there) is all you need
# to add a new binary cache - no manual import list to update.
{ pkgs, lib, ... }:

let
  folder = ./cachix;
  # Build a path like ./cachix/foo.nix for each entry
  toImport = name: value: folder + ("/" + name);
  # Keep only regular files ending in .nix (skip directories, lock files, etc.)
  filterCaches = key: value: value == "regular" && lib.hasSuffix ".nix" key;
  imports = lib.mapAttrsToList toImport (lib.filterAttrs filterCaches (builtins.readDir folder));
in {
  inherit imports;
  # Always include the official NixOS cache as a baseline substituter.
  nix.settings.substituters = ["https://cache.nixos.org/"];
}
