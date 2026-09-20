{
  config,
  lib,
  osConfig ? null,
  ...
}:
{
  imports = [
    ./noctalia
    ./quickshell
    ./jes
  ];

  # Per-user shell selection. Defaults to the host's nixtop.shell (NixOS
  # option, read via osConfig); a user's home.nix may override it for that
  # user only. Every shell module below follows this value, and the mango /
  # sway variants adapt to it. "none" is waybar-only (no shell).
  options.nixtop.shell = lib.mkOption {
    type = lib.types.enum [
      "noctalia"
      "quickshell"
      "jes"
      "none"
    ];
    default = if osConfig != null then osConfig.nixtop.shell or "none" else "none";
    description = "Which shell owns this user's session. Defaults to the host nixtop.shell.";
  };
}
