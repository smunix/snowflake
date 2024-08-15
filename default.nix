{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib.attrsets)
    attrValues
    filterAttrs
    mapAttrs
    mapAttrsToList
    ;
  inherit (lib.modules)
    mkAliasOptionModule
    mkDefault
    mkForce
    mkIf
    ;
  inherit (lib.my) mapModulesRec';
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    (mkAliasOptionModule [ "hm" ] [
      "home-manager"
      "users"
      config.user.name
    ])
  ] ++ (mapModulesRec' (toString ./modules) import);

  # Common config for all nixos machines;
  environment.variables = {
    SNOWFLAKE = config.snowflake.dir;
    SNOWFLAKE_BIN = config.snowflake.binDir;
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  nix =
    let
      filteredInputs = filterAttrs (n: _: n != "self") inputs;
      nixPathInputs = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
      registryInputs = mapAttrs (_: v: { flake = v; }) filteredInputs;
    in
    {
      package = pkgs.nixVersions.stable;
      # extraOptions = ''
      #   accept-flake-config = true
      #   allow-import-from-derivation = true
      #   experimental-features = nix-command flakes
      #   narinfo-cache-negative-ttl = 5
      # '';

      nixPath = nixPathInputs ++ [
        "nixpkgs-overlays=${config.snowflake.dir}/overlays"
        "snowflake=${config.snowflake.dir}"
      ];

      optimise = {
        automatic = true;
        dates = [ "02:00" ];
      };

      registry = registryInputs // {
        snowflake.flake = inputs.self;
      };

      settings = {
        accept-flake-config = lib.mkDefault true;
        allow-import-from-derivation = lib.mkDefault true;
        auto-optimise-store = true;
        experimental-features = lib.mkDefault [
          "nix-command"
          "flakes"
        ];
        narinfo-cache-negative-ttl = lib.mkDefault 5;
        substituters = [
          "https://nix-community.cachix.org"
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };

  system = {
    stateVersion = "24.05";
    configurationRevision = with inputs; mkIf (self ? rev) self.rev;
  };

  # Some reasonable, global defaults
  ## This is here to appease 'nix flake check' for generic hosts with no
  ## hardware-configuration.nix or fileSystem config.
  fileSystems."/".device = mkDefault "/dev/disk/by-label/nixos";

  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    kernelParams = [ "pcie_aspm.policy=performance" ];
    loader = {
      efi.efiSysMountPoint = "/boot";
      efi.canTouchEfiVariables = mkDefault true;
      systemd-boot.enable = mkDefault true;
      grub = {
        enable = mkDefault false;
        device = "nodev";
        efiSupport = mkDefault true;
        useOSProber = mkDefault true;
      };
    };
  };

  console = {
    font = mkDefault "Lat2-Terminus16";
    useXkbConfig = mkDefault true;
  };

  time.timeZone = mkDefault "America/New_York";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  i18n.defaultLocale = mkDefault "en_US.UTF-8";

  # WARNING: prevent installing pre-defined packages
  environment.defaultPackages = [ ];

  environment.systemPackages = attrValues {
    inherit (pkgs)
      cached-nix-shell
      dtrx
      jless
      gnumake
      # unrar
      pmutils
      unzip
      ;
  };
}
