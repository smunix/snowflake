{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkDefault mkIf mkMerge;
  cfg = config.modules.shell.toolset.nix;
in {
  options.modules.shell.toolset.nix = let
    inherit (lib.options) mkEnableOption;
  in {
    nix-index.enable = mkEnableOption "system nix-index";
  };

  config = mkMerge [
    (mkIf config.modules.shell.toolset.nix.nix-index.enable {
      hm.programs.nix-index = {
        enable = true;
      };

      # see https://paperless.blog/systemd-services-and-timers-in-nixos
      #     https://github.com/mcdonc/.nixconfig/blob/master/videos/userservice/script.rst
      systemd.user.services.nix-index = {
        description = "run nix-index";
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${getExe' config.hm.programs.nix-index.package "nix-index"}'';
        };
        startAt = "daily";
      };
    })
  ];
}
