{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
in
{
  options.modules.shell.nushell =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "nushell shell" // {
        default = true;
      };
    };

  config = mkIf config.modules.shell.nushell.enable {
    modules.shell = {
      corePkgs.enable = true;
      toolset = {
        # Enable starship-rs + ZSH integration
        starship.enable = true;
      };
    };

    hm.programs.starship.enableBashIntegration = true;

    hm.programs.nushell = {
      enable = true;
      shellAliases = {
        ls = "lsd -Sl";
        lsa = "lsd -Sla";
        less = "less -R";
        wup = "systemctl start wg-quick-Akkadian-VPN.service";
        wud = "systemctl stop wg-quick-Akkadian-VPN.service";
      };
    };
  };
}
