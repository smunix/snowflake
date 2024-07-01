{
  options,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # https://www.youtube.com/watch?v=61wGzIv12Ds
  inherit (builtins) readFile toPath;
  inherit (lib.attrsets) attrValues mapAttrsToList;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  env = {
    LIBVA_DRIVER_NAME = "nvidia-drm";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia-drm";
    WLR_RENDERER = "nvidia-drm";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    HYPRLAND_TRACE = "1";
    HYPRLAND_LOG_WLR = "1";
  };

in
{
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "hyped wayland WM";
  };

  config = mkIf config.modules.desktop.hyprland.enable {
    modules = {
      desktop = {
        envProto = "wayland";
        toolset.fileManager = {
          enable = true;
          program = "thunar";
        };
        extensions = {
          input-method = {
            enable = true;
            framework = "fcitx";
          };
          mimeApps.enable = true; # mimeApps -> default launch application
          dunst.enable = true;
          waybar.enable = true;
          elkowar.enable = true;
          rofi.enable = true;
        };
      };
      shell.scripts = {
        brightness.enable = true;
        screenshot.enable = true; # TODO
      };
      hardware.kmonad.enable = false;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ (xdg-desktop-portal-hyprland.override { inherit hyprland; }) ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
    };

    user.packages = attrValues { inherit (pkgs) egl-wayland eglexternalplatform libglvnd; };

    environment = {
      sessionVariables = env;
      systemPackages = attrValues {
        inherit (pkgs)
          # eww

          imv
          libnotify
          playerctl
          wf-recorder
          wlr-randr
          # wallpapers

          hyprpaper
          swaybg
          wpaperd
          mpvpaper
          swww
          # gtk rofi

          wofi
          # hyprland wiki also suggests

          bemenu
          fuzzel
          tofi

          glxinfo

          # nvidia stuff
          # vulkan
          vulkan-loader
          vulkan-tools
          vulkan-validation-layers
          ;

        # waybar = (
        #   pkgs.waybar.overrideAttrs (o: {
        #     mesonFlags = o.mesonFlags ++ [ "-Dexperimental=true" ];
        #   })
        # );
      };
    };

    hm = {
      imports = with inputs; [ (import "${hyprland}/nix/hm-module.nix" hyprland) ];

      wayland.windowManager.hyprland = {
        enable = true;
        package = pkgs.hyprland-debug;
        # extraConfig = readFile "${config.snowflake.configDir}/hyprland/hyprland.conf";
        # xwayland.enable = true;
        settings = {
          # monitor = ",preferred,auto,1";
          monitor = ",highres,auto,auto";

          env = mapAttrsToList (n: v: "${n},${v}") env;

          "$terminal" = "rio";
          "$menu" = "rofi -show";
          "$fileManager" = "thunar";

          # Key bindings

          "$mod" = "SUPER";

          windowrulev2 = [ "float, class:^system-monitor$" ];

          debug = {
            disable_logs = false;
          };

          bind = [
            # System keys
            "$mod SHIFT, q, exit"
            "$mod SHIFT, c, killactive"
            "$mod SHIFT, space, fullscreen"
            "$mod, f, togglefloating"

            # Menu
            "$mod, p, exec, $menu run"

            # Workspaces
            ## cycle workspaces
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod, 6, workspace, 6"
            "$mod, 7, workspace, 7"
            "$mod, 8, workspace, 8"
            "$mod, 9, workspace, 9"
            "$mod, 10, workspace, 10"
            "$mod, s, togglespecialworkspace"

            ## move between workspaces
            "$mod SHIFT, 1, movetoworkspacesilent, 1"
            "$mod SHIFT, 2, movetoworkspacesilent, 2"
            "$mod SHIFT, 3, movetoworkspacesilent, 3"
            "$mod SHIFT, 4, movetoworkspacesilent, 4"
            "$mod SHIFT, 5, movetoworkspacesilent, 5"
            "$mod SHIFT, 6, movetoworkspacesilent, 6"
            "$mod SHIFT, 7, movetoworkspacesilent, 7"
            "$mod SHIFT, 8, movetoworkspacesilent, 8"
            "$mod SHIFT, 9, movetoworkspacesilent, 9"
            "$mod SHIFT, 10, movetoworkspacesilent, 10"
            "$mod SHIFT, s, movetoworkspacesilent, special"

            ## Movement direction
            "$mod, left, movefocus, h"
            "$mod, right, movefocus, l"
            "$mod, up, movefocus, k"
            "$mod, down, movefocus, j"

            # "$mod, X, exec, $terminal --class system-monitor -e btop"
            "$mod, x, exec, $terminal"
            "$mod, return, exec, $terminal"
            "$mod, b, exec, brave"
          ];

          bindm = [
            "$mod, mouse:272, movewindow" # 272 -> Left-Mouse button
            "$mod, mouse:273, resizewindow" # 273 -> Right-Mouse button
          ];

          cursor = {
            no_hardware_cursors = true;
          };

          input = {
            kb_layout = "us";
            follow_mouse = 1;
            accel_profile = "flat";
            sensitivity = 1.0;
            numlock_by_default = true;

            touchpad = {
              disable_while_typing = 1;
              natural_scroll = 1;
              clickfinger_behavior = 1;
              middle_button_emulation = 1;
              tap-to-click = 1;
            };
          };

          gestures = {
            workspace_swipe = true;
            workspace_swipe_fingers = 3;
            workspace_swipe_invert = true;
            workspace_swipe_min_speed_to_force = 5;
          };

          general = {
            apply_sens_to_raw = false;
            border_size = 2;
            "col.active_border" = "rgba(f38ba8ff)";
            "col.inactive_border" = "rgba(181825ff)";
            gaps_in = 5;
            gaps_out = 5;
            layout = "master"; # master | dwindle
          };

          decoration = {
            # blur = {
            #     enabled           = false
            #     size              = 3
            #     passes            = 1
            #     new_optimizations = true
            # }
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            fullscreen_opacity = 1.0;
            dim_inactive = true;
            dim_strength = 0.2;
            drop_shadow = true;
            rounding = 10;
            # shadow_offset          = [0, 0]
          };

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          dwindle = {
            force_split = 0;
            no_gaps_when_only = true;
            preserve_split = true;
            pseudotile = true;
            special_scale_factor = 0.8;
            split_width_multiplier = 1.0;
            use_active_for_splits = true;
          };

          master = {
            new_status = "master";
            # new_is_master        = true;
            new_on_top = true;
            no_gaps_when_only = true;
            special_scale_factor = 0.8;
          };

          misc = {
            force_default_wallpaper = -1;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            mouse_move_enables_dpms = true;
          };
        };
      };
    };

    home = {
      # System wallpaper:
      configFile.hypr-wallpaper =
        let
          inherit (config.modules.themes) wallpaper;
        in
        mkIf (wallpaper != null) {
          target = "hypr/hyprpaper.conf";
          text = ''
            preload = ${toPath wallpaper}
            wallpaper = DP-2,${toPath wallpaper}
            ipc = off
          '';
        };
    };
  };
}
