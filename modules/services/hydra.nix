{
  options,
  config,
  lib,
  ...
}:
let
  inherit (builtins) filter pathExists;
  inherit (lib.modules) mkIf;
in
{
  options.modules.services.hydra =
    let
      inherit (lib.options) mkEnableOption;
    in
      {
        enable = mkEnableOption "Hydra CI/CD";
      };

  config = mkIf config.modules.services.hydra.enable {
    services.hydra = {
      enable = true;
      hydraURL = "http://localhost:3000";
      notificationSender = "hydra@localhost";
      buildMachinesFiles = [];
      useSubstitutes = true;
    };
  };
}
