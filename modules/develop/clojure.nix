{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.develop.clojure;
  devCfg = config.modules.develop.xdg;
in {
  options.modules.develop.clojure = {
    enable = mkBoolOpt false;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = [
        pkgs.clojure
        pkgs.joker
        pkgs.leiningen
      ];
    })

    (mkIf devCfg.enable {
      # TODO:
    })
  ];
}
