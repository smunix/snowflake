{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
in
{
  options.modules.develop.zig =
    let
      inherit (lib.options) mkOption mkEnableOption;
      inherit (lib.types) enum nullOr;
    in
    {
      enable = mkEnableOption "Zig development";
      version = mkOption {
        type = nullOr (enum [
          "master"
          "0.13.0"
        ]);
        default = "master";
        description = "Which Zig configuration to setup.";
      };
    };

  config =
    let
      zig-version = config.modules.develop.zig.version;
      zig = inputs.zig-overlay.packages.${pkgs.system}.${zig-version}.overrideAttrs (o: {
        version = "${o.version}-${builtins.substring 0 10 inputs.zig-overlay.rev}";
      });
      # https://github.com/zigtools/zls/blob/c5ceadf362df07aa40b657db166bf6229a5ea1c5/flake.nix#L41
      zls =
        (pkgs.stdenvNoCC.mkDerivation {
          name = "zls-${builtins.substring 0 10 inputs.zls.rev}";
          version = "master";
          src = pkgs.lib.cleanSource inputs.zls;
          inherit (inputs) langref;
          buildPhase = ''
            mkdir -p .cache
            ln -s ${pkgs.callPackage "${inputs.zls}/deps.nix" { inherit zig; }} .cache/p
            ${zig}/bin/zig build install --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dversion_data_path=$langref -Dcpu=baseline -Doptimize=ReleaseSafe --prefix $out/
          '';
          checkPhase = ''
            ${zig}/bin/zig build test --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dversion_data_path=$langref -Dcpu=baseline
          '';
        }).overrideAttrs
          (o: {
            version = "${builtins.substring 0 10 inputs.zls.rev}";
          });
    in
    mkMerge [
      (mkIf config.modules.develop.zig.enable {
        user.packages = attrValues { inherit zig zls; };

        hm.programs.vscode.extensions = attrValues { inherit (pkgs.vscode-extensions.ziglang) vscode-zig; };
      })

      (mkIf config.modules.develop.xdg.enable {
        # env = {
        #   ZIG_GLOBAL_CACHE_DIR = "$TMPDIR/zig-cache";
        # };
      })
    ];
}
