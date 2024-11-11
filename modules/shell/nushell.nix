{
  config,
  options,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;

  cfg = config.modules.shell;
in {
  config = mkIf (cfg.default == "nushell") {
    modules.shell = {
      corePkgs.enable = true;
      toolset = {
        macchina.enable = true;
        starship.enable = true;
      };
    };

    # hm.programs.starship.enableNushellIntegration = true;

    # Enable completion for sys-packages:
    # environment.pathsToLink = [ "/share/zsh" ];

    hm.programs.zellij = {
      enable = true;
    };

    environment.variables.SHELL = "${pkgs.nushell}/bin/nu";

    hm.programs.starship.enableBashIntegration = true;

    hm.programs.nushell = {
      enable = true;
      shellAliases = {
        ls = "lsd -Sl";
        lsa = "lsd -Sla";
        less = "less -R";
        wup = "systemctl start wg-quick-Akkadian-VPN.service";
        wud = "systemctl stop wg-quick-Akkadian-VPN.service";
        z = "zeditor";
        zed = "zeditor";
      };
    };
  };
}
