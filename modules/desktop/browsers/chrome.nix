{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep;
in
{
  options.modules.desktop.browsers.chrome =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Google chrome";
    };

  config = mkIf config.modules.desktop.browsers.chrome.enable {
    user.packages =
      let
        inherit (pkgs) makeDesktopItem google-chrome;
      in
      [
        (makeDesktopItem {
          name = "google-chrome";
          desktopName = "Google Web Browser";
          genericName = "Launch a google Chrome Instance";
          icon = "chrome";
          exec = "${google-chrome}/bin/chrome --incognito";
          categories = [ "Network" ];
        })
      ];
    };
}
