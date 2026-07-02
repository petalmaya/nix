{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.zen.enable = lib.mkEnableOption "Zen browser configuration";

  config = lib.mkIf config.nixtop.apps.zen.enable {
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    programs.zen-browser = {
      enable = true;
      profiles.default = {
        isDefault = true;
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          ublock-origin
          darkreader
          bitwarden
          sponsorblock
        ];
        settings = {
          "extensions.autoDisableScopes" = 0;
        };
        # Declarative mod installation from Zen theme store
        # Find mod UUIDs at: https://zen-browser.app/mods
        mods = [
          "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
          "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
          "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
          "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
          "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
          "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
          "5941aefd-67b0-453d-9b62-9071a31cbb0d" # Smaller Compact Bar
        ];
      };
    };
  };
}
