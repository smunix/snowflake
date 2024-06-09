{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.desktop.education;
in
{
  options.modules.desktop.education =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      memorization.enable = mkEnableOption "SUID tool (sandbox)";
      vidcom.enable = mkEnableOption "jailed zoom-us";
    };

  config = mkMerge [
    (mkIf cfg.memorization.enable {
      # TODO: Configure anki OR replace with other software
      user.packages = [ pkgs.anki ];
    })

    (mkIf cfg.vidcom.enable {
      programs.firejail = {
        enable = false;
        wrappedBinaries.zoom = {
          executable = "${getExe pkgs.zoom-us}";
          profile = "${pkgs.firejail}/etc/firejail/zoom.profile";
        };
      };

      user.packages = with pkgs; [
        zoom-us
        obs-studio
        (makeDesktopItem {
          name = "zoom-us";
          desktopName = "Zoom";
          icon = "Zoom";
          exec = "${zoom-us}/bin/zoom";
          genericName = "Video Conference";
          categories = [
            "Network"
            "VideoConference"
          ];
        })
      ];
    })
  ];
}
