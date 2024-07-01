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
      # settings = [
      #   {
      #     "layer" = "top";
      #     "position" = "top";
      #     modules-left = [
      #       "custom/launcher"
      #       "wlr/workspaces"
      #       "temperature"
      #       "idle_inhibitor"
      #       "mpd"
      #     ];
      #     modules-center = [ "clock" ];
      #     modules-right = [
      #       "memory"
      #       "cpu"
      #       "network"
      #       "battery"
      #       "custom/powermenu"
      #       "tray"
      #     ];
      #     "custom/launcher" = {
      #       "format" = "  NixOS";
      #       "on-click" = "rofi -no-lazy-grab -show drun -modi drun";
      #       "tooltip" = false;
      #     };

      #     "wlr/workspaces" = {
      #       "format" = "{icon}";
      #       "on-click" = "activate";
      #       "on-scroll-up" = "hyprctl dispatch workspace e+1";
      #       "on-scroll-down" = "hyprctl dispatch workspace e-1";
      #     };
      #     "idle_inhibitor" = {
      #       "format" = "{icon}";
      #       "format-icons" = {
      #         "activated" = "";
      #         "deactivated" = "";
      #       };
      #       "tooltip" = false;
      #     };
      #     "battery" = {
      #       "interval" = 10;
      #       "states" = {
      #         "warning" = 20;
      #         "critical" = 10;
      #       };
      #       "format" = "{icon} {capacity}%";
      #       "format-icons" = [
      #         ""
      #         ""
      #         ""
      #         ""
      #         ""
      #         ""
      #         ""
      #         ""
      #         ""
      #       ];
      #       "format-full" = "{icon} {capacity}%";
      #       "format-charging" = " {capacity}%";
      #       "tooltip" = false;
      #     };
      #     "clock" = {
      #       "on-click" = "wallpaper_random";
      #       "on-click-right" = "killall dynamic_wallpaper || dynamic_wallpaper &";
      #       "interval" = 1;
      #       "format" = "{:%I:%M %p  %A %b %d}";
      #       "tooltip" = true;
      #       # "tooltip-format"= "{=%A; %d %B %Y}\n<tt>{calendar}</tt>"
      #       "tooltip-format" = ''
      #         上午：高数
      #         下午：Ps
      #         晚上：Golang
      #         <tt>{calendar}</tt>'';
      #     };
      #     "memory" = {
      #       "interval" = 1;
      #       "format" = "﬙ {percentage}%";
      #       "states" = {
      #         "warning" = 85;
      #       };
      #     };
      #     "cpu" = {
      #       "interval" = 1;
      #       "format" = " {usage}%";
      #     };
      #     "mpd" = {
      #       "max-length" = 25;
      #       "format" = "<span foreground='#bb9af7'></span> {title}";
      #       "format-paused" = " {title}";
      #       "format-stopped" = "<span foreground='#bb9af7'></span>";
      #       "format-disconnected" = "";
      #       "on-click" = "mpc --quiet toggle";
      #       "on-click-right" = "mpc ls | mpc add";
      #       "on-click-middle" = "kitty --class='ncmpcpp' --hold sh -c 'ncmpcpp'";
      #       "on-scroll-up" = "mpc --quiet prev";
      #       "on-scroll-down" = "mpc --quiet next";
      #       "smooth-scrolling-threshold" = 5;
      #       "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
      #     };
      #     "network" = {
      #       "interval" = 1;
      #       "format-wifi" = "說 {essid}";
      #       "format-ethernet" = "  {ifname} ({ipaddr})";
      #       "format-linked" = "說 {essid} (No IP)";
      #       "format-disconnected" = "說 Disconnected";
      #       "tooltip" = false;
      #     };
      #     "temperature" = {
      #       # "hwmon-path"= "${env:HWMON_PATH}";
      #       #"critical-threshold"= 80;
      #       "tooltip" = false;
      #       "format" = " {temperatureC}°C";
      #     };
      #     "custom/powermenu" = {
      #       "format" = "";
      #       "on-click" = ""; # TODO
      #       "tooltip" = false;
      #     };
      #     "tray" = {
      #       "icon-size" = 15;
      #       "spacing" = 5;
      #     };
      #   }
      # ];
      # style = ''
      #         * {
      #           font-family: "VictorMono Nerd Font";
      #           font-size: 9pt;
      #           font-weight: bold;
      #           border-radius: 1px;
      #           transition-property: background-color;
      #           transition-duration: 0.5s;
      #         }
      #         @keyframes blink_red {
      #           to {
      #             background-color: rgb(242, 143, 173);
      #             color: rgb(26, 24, 38);
      #           }
      #         }
      #         .warning, .critical, .urgent {
      #           animation-name: blink_red;
      #           animation-duration: 1s;
      #           animation-timing-function: linear;
      #           animation-iteration-count: infinite;
      #           animation-direction: alternate;
      #         }
      #         window#waybar {
      #           background-color: transparent;
      #         }
      #         window > box {
      #           margin-left: 5px;
      #           margin-right: 5px;
      #           margin-top: 5px;
      #           background-color: rgb(30, 30, 46);
      #         }
      #   #workspaces {
      #           padding-left: 0px;
      #           padding-right: 4px;
      #         }
      #   #workspaces button {
      #           padding-top: 5px;
      #           padding-bottom: 5px;
      #           padding-left: 6px;
      #           padding-right: 6px;
      #         }
      #   #workspaces button.active {
      #           background-color: rgb(181, 232, 224);
      #           color: rgb(26, 24, 38);
      #         }
      #   #workspaces button.urgent {
      #           color: rgb(26, 24, 38);
      #         }
      #   #workspaces button:hover {
      #           background-color: rgb(248, 189, 150);
      #           color: rgb(26, 24, 38);
      #         }
      #         tooltip {
      #           background: rgb(48, 45, 65);
      #         }
      #         tooltip label {
      #           color: rgb(217, 224, 238);
      #         }
      #   #custom-launcher {
      #           font-size: 20px;
      #           padding-left: 8px;
      #           padding-right: 6px;
      #           color: #7ebae4;
      #         }
      #   #mode, #clock, #memory, #temperature,#cpu,#mpd, #idle_inhibitor, #temperature, #backlight, #pulseaudio, #network, #battery, #custom-powermenu, #custom-cava-internal {
      #           padding-left: 10px;
      #           padding-right: 10px;
      #         }
      #         /* #mode { */
      #         /* 	margin-left: 10px; */
      #         /* 	background-color: rgb(248, 189, 150); */
      #         /*     color: rgb(26, 24, 38); */
      #         /* } */
      #   #memory {
      #           color: rgb(181, 232, 224);
      #         }
      #   #cpu {
      #           color: rgb(245, 194, 231);
      #         }
      #   #clock {
      #           color: rgb(217, 224, 238);
      #         }
      #   #idle_inhibitor {
      #           color: rgb(221, 182, 242);
      #         }
      #   #temperature {
      #           color: rgb(150, 205, 251);
      #         }
      #   #backlight {
      #           color: rgb(248, 189, 150);
      #         }
      #   #pulseaudio {
      #           color: rgb(245, 224, 220);
      #         }
      #   #network {
      #           color: #ABE9B3;
      #         }
      #   #network.disconnected {
      #           color: rgb(255, 255, 255);
      #         }
      #   #battery.charging, #battery.full, #battery.discharging {
      #           color: rgb(250, 227, 176);
      #         }
      #   #battery.critical:not(.charging) {
      #           color: rgb(242, 143, 173);
      #         }
      #   #custom-powermenu {
      #           color: rgb(242, 143, 173);
      #         }
      #   #tray {
      #           padding-right: 8px;
      #           padding-left: 10px;
      #         }
      #   #mpd.paused {
      #           color: #414868;
      #           font-style: italic;
      #         }
      #   #mpd.stopped {
      #           background: transparent;
      #         }
      #   #mpd {
      #           color: #c0caf5;
      #         }
      #   #custom-cava-internal{
      #           font-family: "Hack Nerd Font" ;
      #         }
      # '';
    };
  };
}
