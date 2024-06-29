{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.shell;
in
{
  options.modules.shell =
    let
      inherit (lib.options) mkOption mkEnableOption;
      inherit (lib.types) nullOr enum;
    in
    {
      default = mkOption {
        type = nullOr (enum [
          "fish"
          "nushell"
          "zsh"
          "xonsh"
        ]);
        default = null;
        description = "Default system shell";
      };
      corePkgs.enable = mkEnableOption "core shell packages";
    };

  config = mkMerge [
    (mkIf (cfg.default != null) {
      users.defaultUserShell =
        if cfg.default == "nushell" then "${pkgs.nushell}/bin/nu" else pkgs."${cfg.default}";
    })

    (mkIf cfg.corePkgs.enable {
      modules.shell.toolset = {
        lsd.enable = true;
        btop.enable = true;
        fzf.enable = true;
      };

      hm.programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config.whitelist.prefix = [ "/home" ];
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 14d --keep 3";
        flake = "/home/smunix/Workspace/public/snowflake";
      };

      user.packages = attrValues {
        inherit (pkgs)
          ack
          any-nix-shell
          dtrx
          file
          hecate
          joshuto
          pwgen
          ranger
          ripdrag
          ripgrep
          rsync
          xclip
          yt-dlp
          yazi
          ;

        # GNU Alternatives
        inherit (pkgs) bat fd zoxide;
        rgFull = pkgs.ripgrep.override { withPCRE2 = true; };
      };
    })
  ];
}
