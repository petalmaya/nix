{
  config,
  lib,
  osConfig ? null,
  ...
}:
{
  # Per-user shell selection. Defaults to the host's nixtop.shell (NixOS
  # option, read via osConfig); setting it in a user's home.nix overrides the
  # host for that user only — e.g. alice on JES while lewis stays waybar-only
  # on the same host. All HM shell consumers (sway variant, jes/noctalia/
  # quickshell enables, mango variant) read this, never osConfig directly.
  # NixOS-side consumers (greeter default session) still follow the host value.
  options.nixtop.shell = lib.mkOption {
    type = lib.types.enum [
      "noctalia"
      "quickshell"
      "jes"
      "lucid"
      "none"
    ];
    default = if osConfig != null then osConfig.nixtop.shell or "none" else "none";
    description = "Which shell owns this user's session. Defaults to the host nixtop.shell.";
  };
}
