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
        nix = {
          nix-index.enable = true;
        };
      };
    };

    networking.networkManager.enable = true;

    services.ssh.enable = true;
    services.hydra.enable = false;

    themes.active = "catppuccin";

    develop = {
      haskell.enable = true;
      nix.enable = true;
      python.enable = true;
      rust.enable = true;
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
      education = {
        vidcom.enable = true;
      };
      browsers = {
        default = "brave";
        brave = {
          enable = true;
        };
        chrome = {
          enable = false;
        };
        firefox = {
          enable = false;
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
  };
}
