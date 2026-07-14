# nix-ld lets dynamically-linked binaries (e.g. pre-built game mods, AppImages,
# random downloads) run on NixOS without repackaging them.  It works by
# providing a fake ld-linux stub at the path those binaries hardcode, and
# making the listed libraries available to them at runtime.
#
# (Funny part is im just gonna keep using steam-run lol)
{
  pkgs,
  ...
}:
{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      dconf  # GSettings / GNOME config system

      # Fonts & multimedia
      fontconfig
      freetype
      SDL2
      SDL2_image
      SDL2_mixer
      SDL2_ttf

      # C runtime & common compression/crypto
      stdenv.cc.cc
      zlib
      zstd
      bzip2
      xz
      libgcc
      openssl
      curl

      # Graphics / windowing
      libglvnd
      mesa
      vulkan-loader
      sdl3
      sdl2-compat

      libX11
      libXext
      libXrender
      libXfixes
      libXcursor
      libXi
      libXrandr
      libXinerama
      libXdamage
      libXcomposite
      libxcb
      libXau
      libXdmcp

      wayland
      libxkbcommon

      # Audio
      alsa-lib
      pulseaudio

      # Odds and ends often needed
      glib
      gtk3
      nss
      nspr
      dbus
      expat
      libdrm
      udev
    ];
  };
}
