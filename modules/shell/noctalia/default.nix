{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.nixtop.noctalia;
  active = config.nixtop.shell == "noctalia";
in
{
  imports =
    if inputs.noctalia-shell ? homeModules then
      builtins.attrValues inputs.noctalia-shell.homeModules
    else if inputs.noctalia-shell ? homeManagerModules then
      builtins.attrValues inputs.noctalia-shell.homeManagerModules
    else
      [ ];

  options.nixtop.noctalia.enable = lib.mkOption {
    type = lib.types.bool;
    default = active;
    description = "Enable the Noctalia shell. Follows nixtop.shell when unset.";
  };
  options.nixtop.noctalia.compositor = lib.mkOption {
    type = lib.types.enum [
      "sway"
      "mango"
    ];
    default = "sway";
    description = "Which compositor session Noctalia runs in.";
  };

  config = lib.mkIf (cfg.enable && active) {
    programs.noctalia = {
      enable = true;
      settings = {
        theme = {
          source = "custom";
          custom_palette = "nixtop";
          # Noctalia renders these itself; matugen must not also write them.
          templates.user.mango = {
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/mango.conf";
            output_path = "$XDG_STATE_HOME/nixtop/theme/mango.conf";
            post_hook = "mmsg dispatch reload_config 2>/dev/null || true";
          };
          templates.user.starship = {
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/starship.toml";
            output_path = "$XDG_CONFIG_HOME/starship.toml";
          };
        };
        bar."default".shadow = false;
        bar."default".contact_shadow = false;
        dock.shadow = false;
        shell.panel.shadow = false;
      };
    };

    xdg.configFile."noctalia/templates/mango.conf".source = ./templates/mango.conf;
    xdg.configFile."noctalia/templates/starship.toml".source = ./templates/starship.toml;

    nixtop.services.matugen.templates.mango.enable = lib.mkDefault false;
    nixtop.services.matugen.templates.starship.enable = lib.mkDefault false;

    home.activation.ensureNoctaliaDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/noctalia/palettes"
    '';

    assertions = [
      {
        assertion = !(config.nixtop.quickshell.enable or false);
        message = "nixtop.shell selects one shell – cannot enable both noctalia and quickshell";
      }
      {
        assertion = !(config.nixtop.jes.enable or false);
        message = "nixtop.shell selects one shell – cannot enable both noctalia and jes";
      }
      {
        assertion = cfg.compositor == "sway" || cfg.compositor == "mango";
        message = "nixtop.noctalia.compositor must be sway or mango";
      }
    ];
  };
}
