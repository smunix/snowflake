{ config, lib, pkgs, ... }:
let
  cfg = config.modules.hardware.v4l2loopback;
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) nullOr enum;
in
{
  options.modules.hardware.v4l2loopback = {
    enable = mkEnableOption "v4l2 loopback";
  };
  config = mkIf cfg.enable {
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 video_nr=2,3 card_label=vcam2,vcam3
    '';
  };
}
