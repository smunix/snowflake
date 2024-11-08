{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [./hardware.nix];

  modules = {
    shell = {
      default = "nushell";
      corePkgs.enable = true;
      toolset = {
        git.enable = true;
        gnupg.enable = true;
        nix = {
          nix-index.enable = true;
        };
      };
    };

    networking = {
      networkManager.enable = true;
      # Zig builds now proxy, not sure why?
      # proxy = "http://127.0.0.1:3128";
    };

    services.ssh.enable = true;
    services.hydra.enable = false;

    themes.active = "catppuccin";

    develop = {
      cc.enable = true;
      haskell.enable = true;
      nix.enable = true;
      python.enable = true;
      rust.enable = true;
      zig = {
        enable = true;
        version = "master";
      };
    };

    desktop = {
      deepin.enable = true;
      hyprland.enable = false;

      # terminal.default = "rio";
      # terminal.default = "wezterm";
      terminal.default = "alacritty";
      editors = {
        default = "nvim";
        neovim = {
          enable = true;
          package = pkgs.neovim;
        };
        emacs.enable = true;
        helix.enable = true;
      };
      education = {
        vidcom.enable = true;
      };
      browsers = {
        default = "brave";
        brave = {
          enable = true;
        };
        chrome = {
          enable = true;
        };
        firefox = {
          enable = true;
          privacy.enable = true;
        };
      };
      toolset = {
        player = {
          music.enable = true;
          video.enable = true;
        };
        social = {
          base.enable = true;
          discord.enable = true;
          matrix.withDaemon.enable = false;
        };
        docViewer = {
          enable = true;
          program = "evince";
        };
      };
    };

    virtualize.enable = "vbox";
  };
}
