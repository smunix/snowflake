{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) isAttrs;
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.my) anyAttrs countAttrs value;

  cfg = config.modules.desktop;
in
{
  options.modules.desktop =
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) nullOr enum;
    in
    {
      envProto = mkOption {
        type = nullOr (enum [
          "x11"
          "wayland"
        ]);
        description = "What display protocol to use.";
        default = null;
      };
    };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = (countAttrs (n: v: n == "enable" && value) cfg) < 2;
          message = "Prevent DE/WM > 1 from being enabled.";
        }
        {
          assertion =
            let
              srv = config.services;
            in
            (srv.xserver.enable && (cfg.envProto == "x11"))
            # || (config.programs.sway.enable)
            || (cfg.envProto == "wayland")
            || !(anyAttrs (n: v: isAttrs v && anyAttrs (n: v: isAttrs v && v.enable)) cfg);
          message = "Prevent desktop applications from enabling without a DE/WM.";
        }
      ];

      env = {
        GTK_DATA_PREFIX = [ "${config.system.path}" ];
        QT_QPA_PLATFORMTHEME = "gnome";
        QT_STYLE_OVERRIDE = "Adwaita";
      };

      system.userActivationScripts.cleanupHome = ''
        pushd "${config.user.home}"
        rm -rf .compose-cache .nv .pki .dbus .fehbg
        [ -s .xsession-errors ] || rm -f .xsession-errors*
        popd
      '';

      user.packages = attrValues {
        inherit (pkgs)
          nvfetcher
          clipboard-jh
          gucharmap
          hyperfine
          kalker
          qgnomeplatform # Qt -> GTK Theme
          # youtube-music
          ;

        kalker-launcher = pkgs.makeDesktopItem {
          name = "Kalker";
          desktopName = "Kalker";
          icon = "calc";
          exec = "${config.modules.desktop.terminal.default} start kalker";
          categories = [
            "Education"
            "Science"
            "Math"
          ];
        };
      };

      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = attrValues { inherit (pkgs) sarasa-gothic scheherazade-new; };
      };

    }

    (mkIf (cfg.envProto == "wayland") {
      security = {
        polkit.enable = true;
        pam.services = {
          swaylock = {
            fprintAuth = false;
          };
        };
      };

      user.packages = with pkgs; [
        swaylock-effects
        swayidle
        sway-audio-idle-inhibit
      ];

      xdg.portal.wlr.enable = true;

      programs = {
        xwayland.enable = true;
        regreet.enable = true;
      };

      services.greetd = {
        enable = true;
        settings = {
          default_session.command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --user-menu \
              --cmd "Hyprland --config ${config.user.home}/.config/hypr/hyprland.conf"
          '';
        };
      };

      environment.etc."greetd/environments".text = ''
        Hyprland
      '';

      hm.services.swayidle =
        let
          lockCmd = "${pkgs.swaylock-effects}/bin/swaylock --screenshots --clock --indicator --effect-blur 7x5 --fade-in 0.2";
        in
        {
          enable = true;
          systemdTarget = "hyprland-session.target";
          timeouts = with pkgs; [
            # {
            #   timeout = 300; # 5 min, lock screen
            #   command = lockCmd;
            # }
            {
              timeout = 600; # 10 min, switch screen off
              command = "hyprctl dispatch dpms off";
              resumeCommand = "hyprctl dispatch dpms on";
            }
            {
              timeout = 900; # 15 min, suspend
              command = "${systemd}/bin/systemctl suspend";
            }
          ];
          events = with pkgs; [
            {
              event = "before-sleep";
              command = lockCmd;
            }
            {
              event = "lock";
              command = lockCmd;
            }
          ];
        };

      hm.wayland.windowManager.sway = {
        enable = false;
        config = rec {
          modifier = "Mod4"; # Super key
          output = {
            "DP-2" = {
              mode = "2560x1440@60Hz";
            };
          };
        };
      };
    })

    (mkIf (cfg.envProto == "x11") {
      security.pam.services = {
        login.enableGnomeKeyring = true;
        lightdm.enableGnomeKeyring = true;
      };

      services.xserver.displayManager.lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = config.user.name;
        };
      };

      # services.xserver.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };
      services.gnome.gnome-keyring.enable = true;

      hm.xsession = {
        enable = true;
        numlock.enable = true;
        preferStatusNotifierItems = true;
      };
    })
  ];
}
