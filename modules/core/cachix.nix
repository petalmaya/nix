# cachix use <name> drops a file in ./cachix/ and it just works
{ lib, ... }:

let
  folder = ./cachix;
  toImport = name: _value: folder + ("/" + name);
  filterCaches = key: value: value == "regular" && lib.hasSuffix ".nix" key;
  imports = lib.mapAttrsToList toImport (lib.filterAttrs filterCaches (builtins.readDir folder));
in
{
  inherit imports;
  nix.settings.substituters = [ "https://cache.nixos.org/" ];
}
