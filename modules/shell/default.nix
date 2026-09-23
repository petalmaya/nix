{
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

  # Per-user shell selection. Defaults to the host value; a user may override.
  # Every shell module follows this value. "none" is waybar-only.
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
