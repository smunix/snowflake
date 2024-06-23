{
  description = "λ simple and configureable Nix-Flake repository!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";

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
    # hyprland.url = "github:hyprwm/Hyprland";
    rust.url = "github:oxalica/rust-overlay";

    # Application -> (Cached) Git
    emacs.url = "github:nix-community/emacs-overlay";
    nvim-nightly.url = "github:nix-community/neovim-nightly-overlay";
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
      pkgs = mkPkgs nixpkgs [ self.overlays.default ];
      pkgs-unstable = mkPkgs nixpkgs-unstable [ self.overlays.default ];

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
