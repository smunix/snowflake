{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./v4l2loopback.nix
  ];

  boot = {
    extraModulePackages = [ ];
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "vmd"
      "usbhid"
      "uas"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "pcie_aspm.policy=performance"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia_drm.fbdev=1" # Disable mesa loading simpledrm
      "nvidia-drm.modeset=1"
    ];

    # Refuse ICMP echo requests on on desktops/laptops; nobody has any business
    # pinging them.
    kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a508aa04-722e-4050-be3a-10ad0d1dbc75";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1122-03FE";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a6648f07-4358-415a-8e91-fb737bd3ec75";
    fsType = "btrfs";
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

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # Hyprland user experience
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;
      powerManagement = {
        enable = true;
        finegrained = false;
      };
    };
    graphics = {
      # opengl formerly
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        vdpauinfo
      ];
    };
    pulseaudio.enable = false;
  };

  # Nix settings
  nix.settings = {
    cores = lib.mkDefault 30;
    max-jobs = lib.mkDefault 60;
    # system-features = lib.mkDefault [ "big-parallel" "kvm" ];
  };

  # CPU
  powerManagement.cpuFreqGovernor = "ondemand";

  services = {
    upower.enable = true;
    xserver = {
      videoDrivers = [ "nvidia" ];
      # videoDrivers = [ "nouveau" ];
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
    v4l2loopback.enable = true;
    kmonad.deviceID = "/dev/input/by-path/usb-Logitech_USB_Receiver-event-kbd";
  };
}
