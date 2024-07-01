{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) nullOr enum;
  cfg = config.modules.desktop.terminal;
in
{
  options.modules.desktop.terminal = {
    default = mkOption {
      type = nullOr (enum [
        "alacritty"
        "kitty"
        "rio"
        "wezterm"
        "xterm"
      ]);
      default = "xterm";
      description = "Default terminal";
      example = "kitty";
    };
  };

  config = mkMerge [
    {
      services.xserver.desktopManager.xterm.enable = mkDefault (cfg.default == "xterm");
      env.TERMINAL = cfg.default;
    }

    (mkIf (cfg.default == "alacritty") { modules.desktop.terminal.alacritty.enable = true; })
    (mkIf (cfg.default == "kitty") { modules.desktop.terminal.kitty.enable = true; })
    (mkIf (cfg.default == "rio") { modules.desktop.terminal.rio.enable = true; })
    (mkIf (cfg.default == "wezterm") { modules.desktop.terminal.wezterm.enable = true; })

    (mkIf (config.modules.desktop.envProto == "x11") {
      services.xserver.excludePackages = mkIf (cfg.default != "xterm") [ pkgs.xterm ];
    })
  ];
}
