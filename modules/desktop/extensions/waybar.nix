{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.modules.desktop.extensions.waybar;
in
{
  options.modules.desktop.extensions.waybar = {
    enable = mkEnableOption "status-bar for wayland";
  };

  config = mkIf cfg.enable {
    # Allow tray-icons to be displayed:
    hm.services.status-notifier-watcher.enable = true;

    # Launch waybar upon entering way-env:
    hm.systemd.user.services.waybar = {
      Unit = {
        Description = "A bar for your wayland environment";
        PartOf = [ "tray.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.waybar.Bar";
        ExecStart = "${getExe pkgs.waybar}";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "tray.target" ];
      };
    };

    hm.programs.waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oa: {
        mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
      });
      style =
        let
          custom = {
            font = "JetBrainsMono Nerd Font";
            font_size = "15px";
            font_weight = "bold";
            text_color = "#cdd6f4";
            secondary_accent = "89b4fa";
            tertiary_accent = "f5f5f5";
            background = "11111B";
            opacity = "0.98";
          };
        in
        ''
          * {
              border: none;
              border-radius: 0px;
              padding: 0;
              margin: 0;
              min-height: 0px;
              font-family: ${custom.font};
              font-weight: ${custom.font_weight};
              opacity: ${custom.opacity};
          }

          window#waybar {
              background: none;
          }

          #workspaces {
              font-size: 18px;
              background-color: rgba(108, 112, 134, 0.3);
              border-radius: 50px;
          }
          #workspaces button {
              color: ${custom.text_color};
              padding-left:  6px;
              padding-right: 9px;
              border-radius: 50px;
          }
          #workspaces button.empty {
              color: #6c7086;
          }
          #workspaces button.active {
              color: #b4befe;
              background-color: rgba(180,190,254,0.3);
          }

          #custom-left {
              background-color: rgba(108, 112, 134, 0.3);
              border-bottom-left-radius: 50px;
              border-top-left-radius: 50px;
          }

          #custom-right {
              background-color: rgba(108, 112, 134, 0.3);
              border-top-right-radius: 50px;
              border-bottom-right-radius: 50px;
          }

          #tray, #pulseaudio, #network, #cpu, #memory, #disk, #clock, #battery, #custom-launcher {
              font-size: ${custom.font_size};
              color: ${custom.text_color};
              background-color: rgba(108, 112, 134, 0.3);
          }

          #cpu {
              padding-left: 15px;
              padding-right: 9px;
          }
          #memory {
              padding-left: 9px;
              padding-right: 9px;
          }
          #disk {
              padding-left: 9px;
              padding-right: 15px;
          }

          #tray {
              padding: 0 20px;
          }

          #pulseaudio {
              padding-left: 9px;
              padding-right: 9px;
          }
          #battery {
              padding-left: 9px;
              padding-right: 9px;
          }
          #network {
              padding-left: 9px;
              padding-right: 15px;
          }

          #clock {
              padding-left: 9px;
              padding-right: 15px;
              margin-right: 30px;
              border-bottom-left-radius: 15px;
              border-bottom-right-radius: 15px;
          }

          #custom-launcher {
              font-size: 20px;
              font-weight: ${custom.font_weight};
              padding-left: 5px;
              padding-right: 15px;
              margin-right: 25px;
              border-bottom-right-radius: 15px;
          }

          #custom-media {
              background-color: rgba(108, 112, 134, 0.3);
          }
        '';
      settings = {
        mainBar = {
          position = "top";
          layer = "top";
          height = 5;
          margin-top = 0;
          margin-bottom = 0;
          margin-left = 0;
          margin-right = 0;
          modules-left = [
            "custom/launcher"
            "hyprland/workspaces"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "custom/left"
            "custom/media"
            "custom/audio_idle_inhibitor"
            "tray"
            "cpu"
            "memory"
            "disk"
            "pulseaudio"
            "network"
          ];
          clock = {
            calendar = {
              format = {
                today = "<span color='#b4befe'><b><u>{}</u></b></span>";
              };
            };
            format = " {:%I:%M %p}";
            tooltip = "true";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = " {:%d/%m}";
          };
          "hyprland/workspaces" = {
            active-only = false;
            disable-scroll = true;
            format = "{icon}";
            on-click = "activate";
            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
              "5" = "󰙯";
              "6" = "";
              "7" = "";
              "8" = " ";
              "10" = "";
              urgent = "";
              default = "";
              sort-by-number = true;
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
              "6" = [ ];
              "7" = [ ];
              "8" = [ ];
            };
          };
          memory = {
            format = "󰟜 {}%";
            format-alt = "󰟜 {used} GiB"; # 
            interval = 2;
          };
          cpu = {
            format = "  {usage}%";
            format-alt = "  {avg_frequency} GHz";
            interval = 2;
          };
          disk = {
            # path = "/";
            format = "󰋊 {percentage_used}%";
            interval = 60;
          };
          network = {
            format-wifi = "  {signalStrength}%";
            format-ethernet = "󰀂 ";
            tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
            format-linked = "{ifname} (No IP)";
            format-disconnected = "󰖪 ";
          };
          tray = {
            icon-size = 20;
            spacing = 8;
          };
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰖁  {volume}%";
            format-icons = {
              default = [ " " ];
            };
            scroll-step = 5;
            on-click = "pamixer -t";
          };
          battery = {
            format = "{icon} {capacity}%";
            format-icons = [
              " "
              " "
              " "
              " "
              " "
            ];
            format-charging = " {capacity}%";
            format-full = " {capacity}%";
            format-warning = " {capacity}%";
            interval = 5;
            states = {
              warning = 20;
            };
            format-time = "{H}h{M}m";
            tooltip = true;
            tooltip-format = "{time}";
          };
          "custom/launcher" = {
            format = "";
            on-click = "pkill wofi || wofi --show drun";
            on-click-right = "pkill wofi || wallpaper-picker";
            tooltip = "false";
          };
          "custom/audio_idle_inhibitor" = {
            format = "{icon}";
            exec = "sway-audio-idle-inhibit --dry-print-both-waybar";
            exec-if = "which sway-audio-idle-inhibit";
            return-type = "json";
            format-icons = {
              output = "";
              input = "";
              output-input = "  ";
              none = "";
            };
          };
          "custom/media" = {
            format = "{icon}{}";
            return-type = "json";
            tooltip = "false";
            format-icons = {
              Playing = " ";
              Paused = " ";
            };
            max-length = 70;
            exec = "playerctl -a metadata --format '{\"text\": \"{{markup_escape(title)}} - {{artist}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
            on-click = "playerctl play-pause";
          };
          "custom/left" = {
            format = "  ";
            tooltip = "false";
          };
          "custom/right" = {
            format = "  ";
            tooltip = "false";
          };
        };
      };
    };
  };
}
