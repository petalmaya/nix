{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jdk25
    ghc
    cabal-install
    haskell-language-server
    python3
  ];
}
