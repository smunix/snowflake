{ pkgs, config, lib, ... }: {

  imports = [ ./hwCfg.nix ];

  # Hardware-related Modules:
  modules.hardware = {
    audio.enable = true;
    openrazer.enable = true;
  };

  # Networking-related Modules:
  modules.networking = {
    enable = true;
    networkManager.enable = true;

    wireGuard.enable = true;
    wireGuard.akkadianVPN.enable = true;
  };

  # XMonad-related Modules:
  modules.desktop = {
    envDisplay.sddm.enable = true;
    envManager.xmonad.enable = true;

    inputMF = {
      fcitx5.enable = true;
      spellCheck.enable = true;
    };

    # Extras Modules for XMonad:
    envExtra = {
      picom.enable = true;
      taffybar.enable = true;
      customLayout.enable = true;
      gtk.enable = true;
      rofi.enable = true;
      dunst.enable = true;
    };

    # WM-Script Modules:
    envScript = {
      brightness.enable = true;
      microphone.enable = true;
      screenshot.enable = true;
      volume.enable = true;
    };
  };

  modules.fonts.entry.enable = true;

  modules.themes.active = "ayu-dark";

  modules.appliance = {
    termEmu = {
      default = "kitty";
      kitty.enable = true;
      alacritty.enable = true;
    };

    editors = {
      default = "emacs";
      emacs.enable = true;
      # nvim.enable = true;
    };

    browsers = {
      default = "firefox";
      firefox.enable = true;
      unGoogled.enable = true;
    };

    extras = {
      chat.enable = true;
      docViewer.enable = true;
      aula.anki.enable = true;
    };

    media = {
      mpv.enable = true;
      spotify.enable = true;
      graphics.enable = true;
    };

    philomath.aula = {
      anki.enable = true;
      # libre.enable = true;
      # zoom.enable = true;
    };

    gaming = {
      steam.enable = true;
      lutris.enable = true;
    };
  };

  # Development-related Modules:
  modules.develop = {
    cc.enable = true;
    haskell.enable = true;
    rust.enable = true;
    nixLang.enable = true;
    # python.enable = true;
    # shell.enable = true;
  };

  # Services-related Modules:
  modules.services = {
    xserver.enable = true;
    xserver.touch.enable = true;
    # ssh.enable = true;

    kdeconnect.enable = true;
    laptop.enable = true;
    transmission.enable = true;
  };

  # Shell-related Modules:
  modules.shell = {
    adb.enable = true;
    gnupg.enable = true;
    git.enable = true;
    bash.enable = true;
    fish.enable = true;
    tmux.enable = true;
    starship.enable = true;
    direnv.enable = true;
    htop.enable = true;
    neofetch.enable = true;
    printTermColor.enable = true;
  };

  boot.kernel.sysctl."abi.vsyscall32" = 0; # League of Legends..
  boot.kernelParams = [ "acpi_backlight=native" ];

  # Remove device entry from file-manager:
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime, x-gvfs-hide" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/home";
    fsType = "ext4";
    options = [ "noatime, x-gvfs-hide" ];

    # TODO: temporary solution for agenix not finding key.
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "x-gvfs-hide" ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl.extraPackages =
      [ pkgs.amdvlk pkgs.driversi686Linux.amdvlk pkgs.rocm-opencl-icd ];
  };

  systemd.services.systemd-udev-settle.enable = false;

  services = {
    avahi.enable = false;
    gvfs.enable = true;
  };

  services.xserver = {
    videoDrivers = [ "amdgpu" ];
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  services.xserver.libinput = {
    touchpad.accelSpeed = "0.5";
    touchpad.accelProfile = "adaptive";
  };
}
