{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [ ./hardware.nix ];

  modules = {
    shell = {
      default = "zsh";
      corePkgs.enable = true;
      toolset = {
        git.enable = true;
        gnupg.enable = true;
      };
    };

    networking.networkManager.enable = true;

    services.ssh.enable = true;
    services.hydra.enable = true;

    themes.active = "catppuccin";

    develop = {
      haskell.enable = true;
      nix.enable = true;
      zig.enable = true;
    };

    desktop = {
      deepin.enable = true;
      terminal = {
        default = "alacritty";
        alacritty.enable = true;
      };
      editors = {
        default = "nvim";
        neovim = {
          enable = true;
          package = pkgs.neovim;
        };
        emacs.enable = true;
      };
      browsers = {
        default = "firefox";
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
          matrix.withDaemon.enable = true;
        };
        docViewer = {
          enable = true;
          program = "evince";
        };
      };
    };
  };
}
