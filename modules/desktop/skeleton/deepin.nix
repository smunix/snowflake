{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
in
{
  options.modules.desktop.deepin =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "modern desktop environment";
    };

  config = mkIf config.modules.desktop.deepin.enable {
    modules.desktop = {
      envProto = "x11";
      extensions.input-method = {
        enable = true;
        framework = "ibus";
      };
    };

    programs.dconf.enable = true;

    services.xserver.desktopManager.deepin = {
      enable = true;
      # debug = true;
    };

    services.deepin = {
      app-services.enable = true;
      dde-api.enable = true;
      dde-daemon.enable = true;
    };

    # services.gnome = {
    #   gnome-browser-connector.enable = true;
    #   sushi.enable = true;
    # };

    services.udev = {
      packages = [ pkgs.gnome.gnome-settings-daemon ];
      extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      '';
    };

    user.packages = attrValues {
      inherit (pkgs.deepin)
        dde-launchpad
        dde-file-manager
        dde-dock
        dde-device-formatter
        dde-control-center
        dde-clipboard
        dde-calendar
        dde-account-faces
        ;
    };

    # Enable chrome-gnome-shell in FireFox nightly (mozilla-overlay):
    # home.file.chrome-gnome-shell = {
    #   target = ".mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json";
    #   source = "${pkgs.chrome-gnome-shell}/lib/mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json";
    # };
  };
}
