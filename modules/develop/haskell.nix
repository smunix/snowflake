{
  config,
  options,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
in
{
  options.modules.develop.haskell =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Haskell development";
    };

  config = mkMerge [
    (mkIf config.modules.develop.haskell.enable {
      user.packages =
        with inputs.nix-utils.lib;
        with pkgs.haskell.lib;
        let
          hpkgs = fast (pkgs.haskell.packages.ghc98.override { inherit (inputs) all-cabal-hashes; }) [
            {
              modifiers = [ ];
              extension = hf: hp: with hf; { };
            }
          ];
        in
        attrValues {
          inherit (hpkgs)
            cabal-install
            fourmolu
            haskell-language-server
            hasktags
            hpack
            ;
          ghc-with-hoogle = hpkgs.ghcWithHoogle (
            p: with p; [
              # taffybar
              # xmonad
              # xmonad-contrib
            ]
          );
        };

      hm.programs.vscode.extensions = with pkgs.vscode-extensions; [
        haskell.haskell
        justusadam.language-haskell # syntax-highlighting
      ];
    })

    (mkIf config.modules.develop.xdg.enable {
      home.file.ghci-conf = {
        target = ".ghci";
        text = ''
          :set -fobject-code
          :set prompt "\ESC[38;5;3m\STXλ>\ESC[m\STX "
          :set prompt-cont "|> "
          :def hoogle \x -> pure $ ":!hoogle search \"" ++ x ++ "\""
        '';
      };
    })
  ];
}
