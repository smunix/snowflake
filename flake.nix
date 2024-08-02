{
  description = "λ simple and configureable Nix-Flake repository!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    systems.url = "github:nix-systems/default-linux";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System application(s)
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Window Manager(s) + Extensions
    xmonad-contrib.url = "github:icy-thought/xmonad-contrib"; # TODO: replace with official after #582 == merged!

    hyprland = {
      # https://github.com/NixOS/nix/issues/4423#issuecomment-2027886625
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1&ref=main";
      flake = false;
    };

    hyprcursor = {
      url = "github:hyprwm/hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.hyprlang.follows = "hyprlang";
    };

    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.hyprutils.follows = "hyprutils";
    };

    hyprutils = {
      url = "github:hyprwm/hyprutils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprwayland-scanner = {
      url = "github:hyprwm/hyprwayland-scanner";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.hyprlang.follows = "hyprlang";
    };

    rust.url = "github:oxalica/rust-overlay";

    # Application -> (Cached) Git
    emacs.url = "github:nix-community/emacs-overlay";

    nvim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    # # Tablines
    # plugin-nvim-bufferline-lua.url = "github:akinsho/nvim-bufferline.lua?ref=main";
    # plugin-nvim-bufferline-lua.flake = false;

    neovim-flake = {
      url = "github:smunix/neovim-flake?ref=smunix";
      # inputs.plugin-nvim-bufferline-lua.follows = "plugin-nvim-bufferline-lua";
      flake = true;
    };

    spicetify-nix.url = "github:the-argus/spicetify-nix";
    firefox.url = "github:nix-community/flake-firefox-nightly";

    # Submodules (temporary) # TODO
    emacs-dir = {
      url = "https://github.com/Icy-Thought/emacs.d.git";
      type = "git";
      submodules = true;
      flake = false;
    };
    emacs-dir-doomemacs = {
      url = "github:ARAKAZA/emacs.d?ref=01-fix-username";
      flake = false;
    };
    doomemacs = {
      url = "github:doomemacs/doomemacs";
      flake = false;
    };
    nvim-dir = {
      url = "https://github.com/Icy-Thought/nvim.d.git";
      type = "git";
      submodules = true;
      flake = false;
    };
    all-cabal-hashes = {
      url = "github:commercialhaskell/all-cabal-hashes?ref=hackage";
      flake = false;
    };
    nix-utils = {
      url = "github:smunix/nix-utils";
      flake = true;
    };
    nix-filter = {
      url = "github:numtide/nix-filter";
      flake = true;
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    langref = {
      # llvm: fix @wasmMemory{Size,Grow} for wasm64
      url = "https://raw.githubusercontent.com/ziglang/zig/0fb2015fd3422fc1df364995f9782dfe7255eccd/doc/langref.html.in";
      flake = false;
    };

    zls = {
      url = "github:zigtools/zls?rev=45eb38e2365c3f9fe7cee5a37a0f8d5c8645f888";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = "https://hyprland.cachix.org";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }:
    let
      inherit (lib.my) mapModules mapModulesRec mapHosts;
      system = "x86_64-linux";

      mkPkgs =
        pkgs: extraOverlays:
        import pkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg [ "spotify" ]);
            nvidia.acceptLicense = true;
          };
          overlays = extraOverlays ++ (lib.attrValues self.overlays);
        };

      pkgs = mkPkgs nixpkgs [
        self.overlays.default
        self.overlays.hyprland
      ];
      pkgs-unstable = mkPkgs nixpkgs-unstable [
        self.overlays.default
        self.overlays.hyprland
      ];

      lib = nixpkgs.lib.extend (
        final: prev: {
          my = import ./lib {
            inherit pkgs inputs;
            lib = final;
          };
        }
      );
    in
    {
      lib = lib.my;

      overlays = (mapModules ./overlays import) // {
        default = final: prev: {
          unstable = pkgs-unstable;
          my = self.packages.${system};
        };

        nvfetcher = final: prev: {
          sources = builtins.mapAttrs (_: p: p.src) (
            (import ./packages/_sources/generated.nix) {
              inherit (final)
                fetchurl
                fetchgit
                fetchFromGitHub
                dockerTools
                ;
            }
          );
        };

        hyprland =
          let
            # props = builtins.fromJSON (builtins.readFile "${inputs.hyprland}/props.json");
            mkDate =
              longDate:
              (lib.concatStringsSep "-" [
                (builtins.substring 0 4 longDate)
                (builtins.substring 4 2 longDate)
                (builtins.substring 6 2 longDate)
              ]);
            date = mkDate (inputs.hyprland.lastModificationDate or "19700101");
          in
          lib.composeManyExtensions [
            inputs.hyprcursor.overlays.default
            inputs.hyprlang.overlays.default
            inputs.hyprutils.overlays.default
            inputs.hyprwayland-scanner.overlays.default
            inputs.xdph.overlays.xdg-desktop-portal-hyprland

            (final: prev: {
              hyprland = final.callPackage "${inputs.hyprland}/nix/default.nix" {
                stdenv = final.gcc13Stdenv;
                # version = "${props.version}+date=${date}_${inputs.hyprland.shortRev or "dirty"}";
                version = "${inputs.hyprland.shortRev or "dirty"}";
                commit = inputs.hyprland.rev or "dirty";
                inherit date;
              };
              hyprland-unwrapped = final.hyprland.override { wrapRuntimeDeps = false; };
              hyprland-debug = final.hyprland.override { debug = true; };
              hyprland-legacy-renderer = final.hyprland.override { legacyRenderer = true; };

              # deprecated packages
              hyprland-nvidia = builtins.trace ''
                hyprland-nvidia was removed. Please use the hyprland package.
                Nvidia patches are no longer needed.
              '' final.hyprland;

              hyprland-hidpi = builtins.trace ''
                hyprland-hidpi was removed. Please use the hyprland package.
                For more information, refer to https://wiki.hyprland.org/Configuring/XWayland.
              '' final.hyprland;
            })
            (final: prev: {
              xwayland = prev.xwayland.overrideAttrs (old: {
                postInstall = ''
                  sed -i '/includedir/d' $out/lib/pkgconfig/xwayland.pc
                '';
              });
            })
          ];
      };

      packages."${system}" = mapModules ./packages (p: pkgs.callPackage p { });

      nixosModules = {
        snowflake = import ./.;
      } // mapModulesRec ./modules import;

      nixosConfigurations = mapHosts ./hosts { };

      devShells."${system}".default = import ./shell.nix { inherit lib pkgs; };

      templates.full = {
        path = ./.;
        description = "λ well-tailored and configureable NixOS system!";
      } // import ./templates;

      templates.default = self.templates.full;

      # TODO: deployment + template tool.
      # apps."${system}" = {
      #   type = "app";
      #   program = ./bin/hagel;
      # };
    };
}
