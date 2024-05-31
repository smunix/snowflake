{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # dratrion hardward-configuration.nix

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "vmd"
    "usbhid"
    "uas"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0226cb4d-48f5-40f2-a51d-c89c5b598bb5";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/49E1-394F";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/d5694105-8839-4b40-ae55-2dcd9874c6a8";
    fsType = "ext4";
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp69s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.pulseaudio.enable = false;
  # dratrion

  ##  fileSystems."/" = {
  ##    device = "/dev/disk/by-label/nixos";
  ##    fsType = "ext4";
  ##    options = ["noatime"];
  ##  };
  ##
  ##  fileSystems."/boot" = {
  ##    device = "/dev/disk/by-label/boot";
  ##    fsType = "vfat";
  ##  };
  ##
  ##  fileSystems."/home" = {
  ##    device = "/dev/disk/by-label/home";
  ##    fsType = "ext4";
  ##    options = ["noatime"];
  ##  };
  ##
  ##  swapDevices = ["/dev/disk/by-label/swap"];
  ##
  ##  boot.kernelParams = [
  ##    # HACK Disables fixes for spectre, meltdown, L1TF and a number of CPU
  ##    #   vulnerabilities for a slight performance boost. Don't copy this blindly!
  ##    #   And especially not for mission critical or server/headless builds
  ##    #   exposed to the world.
  ##    "mitigations=off"
  ##  ];

  # Refuse ICMP echo requests on on desktops/laptops; nobody has any business
  # pinging them.
  boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;

  # CPU
  nix.settings.max-jobs = lib.mkDefault 60;
  powerManagement.cpuFreqGovernor = "performance";

  services = {
    upower.enable = true;
    xserver = {
      videoDrivers = [ "nvidia" ];
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };

  # Here we enable our custom modules (snowflake/modules)
  modules.hardware = {
    pipewire.enable = true;
    bluetooth.enable = true;
    pointer.enable = true;
    printer.enable = true;
  };
}
