{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.meta) getExe;
  inherit (lib.options) mkEnableOption;

  neovimCfg = config.modules.desktop.editors.neovim;
in {
  options.modules.develop.rust = {
    enable = mkEnableOption "Rust development";
  };

  config = mkMerge [
    (mkIf config.modules.develop.rust.enable {
      nixpkgs.overlays = [inputs.fenix.overlays.default];

      user.packages = attrValues {
        # rust-package = pkgs.rust-bin.beta.latest.default;
        inherit (pkgs.fenix.complete) toolchain;
        inherit
          (pkgs)
          # bacon
          # bacon-ls
          # cargo
          cargo-expand
          cargo-nextest
          cargo-watch
          gcc
          # rustc
          # rustfmt
          # rust-analyzer
          # rust-script
          ;
      };

      environment.shellAliases = {
        rs = "rustc";
        ca = "cargo";
      };

      hm.programs.bacon = {
        enable = true;
        package = pkgs.bacon;
      };
      hm.programs.vscode.enable = true;
      hm.programs.vscode.extensions = attrValues {
        inherit (pkgs.vscode-extensions.rust-lang) rust-analyzer;
        inherit (pkgs.vscode-extensions.tuttieee) emacs-mcx;
        inherit (pkgs.vscode-extensions.dracula-theme) theme-dracula;
        inherit (pkgs.vscode-extensions.vscodevim) vim;
      };
    })

    (mkIf (neovimCfg.enable && neovimCfg.template == "nixvim") {
      hm = {
        programs.nixvim = {
          plugins = {
            rustaceanvim = {
              enable = true;
            };
            rust-tools = {
              enable = false;
            };
            # lsp-format.lspServersToEnable = [ "rust-analyzer" ];
            lsp.servers = {
              rust-analyzer = {
                enable = false;
                installCargo = true;
                installRustc = true;
                settings = {
                  cargo.features = "all";
                };
              };
            };
          };
        };
      };
    })

    (mkIf config.modules.develop.xdg.enable {
      env = {
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
        PATH = ["$CARGO_HOME/bin"];
      };
    })
  ];
}
