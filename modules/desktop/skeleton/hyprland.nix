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
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
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
      # extraPortals = with pkgs; [ (xdg-desktop-portal-hyprland.override { inherit hyprland; }) ];
      # https://github.com/flatpak/xdg-desktop-portal/blob/1.18.1/doc/portals.conf.rst.in
      configPackages = with pkgs; [ (xdg-desktop-portal-hyprland.override { inherit hyprland; }) ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
    };

    environment = {
      sessionVariables = env;
    };

    hm = {
      imports = with inputs; [ (import "${hyprland}/nix/hm-module.nix" hyprland) ];

      wayland.windowManager.hyprland = {
        enable = true;
        package = pkgs.hyprland;
        xwayland = {
          enable = true;
        };
        systemd.enable = true;

        settings = with pkgs; {
          # monitor = ",preferred,auto,1";
          monitor = ",highres,auto,auto";

          xwayland = {
            force_zero_scaling = true;
          };

          env = mapAttrsToList (n: v: "${n},${v}") env;

          "$terminal" = "rio";
          "$menu" = "rofi -show";
          "$fileManager" = "${cinnamon.nemo-with-extensions}/bin/nemo";

          # Key bindings

          "$mod" = "SUPER";

          # autostart
          exec-once = [
            "systemctl --user import-environment &"
            "hash dbus-update-activation-environment 2>/dev/null &"
            "dbus-update-activation-environment --systemd &"
            "${networkmanagerapplet}/bin/nm-applet &"
            "${wl-clip-persist}/bin/wl-clip-persist --clipboard both"
            "${swaybg}/bin/swaybg -m fill -i $XDG_DATA_HOME/wallpaper &"
            "sleep 1 && ${swaylock-effects}/bin/swaylock --screenshots --clock --indicator --effect-blur 7x5 --fade-in 0.2"
            "hyprctl setcursor Nordzy-cursors 22 &"
            "${poweralertd}/bin/poweralertd &"
            "waybar &"
            "${mako}/bin/mako &"
            "${wl-clipboard}/bin/wl-paste --watch cliphist store &"
            "${openssh}/bin/ssh-add &"
          ];
          # windowrule
          windowrule = [
            "float,imv"
            "center,imv"
            "size 1200 725,imv"
            "float,mpv"
            "center,mpv"
            "tile,Aseprite"
            "size 1200 725,mpv"
            "float,title:^(float_kitty)$"
            "center,title:^(float_kitty)$"
            "size 950 600,title:^(float_kitty)$"
            "float,audacious"
            "workspace 8 silent, audacious"
            "pin,wofi"
            "float,wofi"
            "noborder,wofi"
            "tile, neovide"
            "idleinhibit focus,mpv"
            "float,udiskie"
            "float,title:^(Transmission)$"
            "float,title:^(Volume Control)$"
            "float,title:^(Firefox — Sharing Indicator)$"
            "move 0 0,title:^(Firefox — Sharing Indicator)$"
            "size 700 450,title:^(Volume Control)$"
            "move 40 55%,title:^(Volume Control)$"
          ];

          # windowrulev2
          windowrulev2 = [
            "workspace 1, class:^(Brave-browser)$"
            "workspace 1, class:^(firefox-nightly)$"
            "workspace 2, class:^(evince)$"
            "workspace 3, class:^(rio)$"
            "float, class:^(rio)$"
            "workspace 7 silent, title:^(.*Private.*)$,class:^(Brave-browser)$"
            "float, title:^(.*Private.*)$,class:^(Brave-browser)$"
            "float, title:^(Picture-in-Picture)$"
            "opacity 1.0 override 1.0 override, title:^(Picture-in-Picture)$"
            "pin, title:^(Picture-in-Picture)$"
            "opacity 1.0 override 1.0 override, title:^(.*imv.*)$"
            "opacity 1.0 override 1.0 override, title:^(.*mpv.*)$"
            "opacity 1.0 override 1.0 override, class:(Aseprite)"
            "opacity 1.0 override 1.0 override, class:(Unity)"
            "idleinhibit focus, class:^(mpv)$"
            "idleinhibit fullscreen, class:^(firefox)$"
            "float,class:^(pavucontrol)$"
            "float,class:^(SoundWireServer)$"
            "float,class:^(.sameboy-wrapped)$"
            "float,class:^(file_progress)$"
            "float,class:^(confirm)$"
            "float,class:^(dialog)$"
            "float,class:^(download)$"
            "float,class:^(notification)$"
            "float,class:^(error)$"
            "float,class:^(confirmreset)$"
            "float,title:^(Open File)$"
            "float,title:^(branchdialog)$"
            "float,title:^(Confirm to replace files)$"
            "float,title:^(File Operation Progress)$"
          ];

          debug = {
            disable_logs = false;
          };

          bind = [
            # show keybinds list
            # "$mod, F1, exec, show-keybinds"

            # keybindings
            "$mod, X, exec, $terminal"
            "ALT, X, exec, $terminal --title Terminal"
            "$mod SHIFT, X, exec, $terminal --start-as=fullscreen -o 'font_size=16'"
            # "$mod, B, exec, hyprctl dispatch exec '[workspace 1 silent] vivaldi'"
            "$mod, Q, killactive,"
            "$mod, F, fullscreen, 0"
            "$mod SHIFT, F, fullscreen, 1"
            "$mod, Space, togglefloating,"
            "$mod, P, exec, pkill wofi || wofi --show drun"
            "$mod SHIFT, D, exec, hyprctl dispatch exec '[workspace 5 silent] discord'"
            "$mod, Escape, exec, ${swaylock-effects}/bin/swaylock --screenshots --clock --indicator --effect-blur 7x5 --fade-in 0.2"
            # "$mod SHIFT, Escape, exec, shutdown-script"
            # "$mod, P, pseudo,"
            "$mod, J, togglesplit,"
            "$mod, E, exec, $fileManager"
            # "$mod SHIFT, B, exec, pkill -SIGUSR1 .waybar-wrapped"
            "$mod, C ,exec, ${hyprpicker}/bin/hyprpicker -a"
            # "$mod, G,exec, $HOME/.local/bin/toggle_layout"
            # "$mod, W,exec, pkill wofi || wallpaper-picker"
            # "$mod SHIFT, W, exec, vm-start"

            # screenshot
            "$mod SHIFT, S, exec, ${grimblast}/bin/grimblast --notify --cursor save area ~/Pictures/$(date +'%Y-%m-%d-At-%Ih%Mm%Ss').png"

            # switch focus
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"

            # switch workspace
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod, 6, workspace, 6"
            "$mod, 7, workspace, 7"
            "$mod, 8, workspace, 8"
            "$mod, 9, workspace, 9"
            "$mod, 0, workspace, 10"

            # same as above, but switch to the workspace
            "$mod SHIFT, 1, movetoworkspacesilent, 1" # movetoworkspacesilent
            "$mod SHIFT, 2, movetoworkspacesilent, 2"
            "$mod SHIFT, 3, movetoworkspacesilent, 3"
            "$mod SHIFT, 4, movetoworkspacesilent, 4"
            "$mod SHIFT, 5, movetoworkspacesilent, 5"
            "$mod SHIFT, 6, movetoworkspacesilent, 6"
            "$mod SHIFT, 7, movetoworkspacesilent, 7"
            "$mod SHIFT, 8, movetoworkspacesilent, 8"
            "$mod SHIFT, 9, movetoworkspacesilent, 9"
            "$mod SHIFT, 0, movetoworkspacesilent, 10"
            "$mod CTRL, c, movetoworkspace, empty"

            # window control
            "$mod SHIFT, left, movewindow, l"
            "$mod SHIFT, right, movewindow, r"
            "$mod SHIFT, up, movewindow, u"
            "$mod SHIFT, down, movewindow, d"
            "$mod CTRL, left, resizeactive, -80 0"
            "$mod CTRL, right, resizeactive, 80 0"
            "$mod CTRL, up, resizeactive, 0 -80"
            "$mod CTRL, down, resizeactive, 0 80"
            "$mod ALT, left, moveactive,  -80 0"
            "$mod ALT, right, moveactive, 80 0"
            "$mod ALT, up, moveactive, 0 -80"
            "$mod ALT, down, moveactive, 0 80"

            # media and volume controls
            ",XF86AudioRaiseVolume,exec, pamixer -i 2"
            ",XF86AudioLowerVolume,exec, pamixer -d 2"
            ",XF86AudioMute,exec, pamixer -t"
            ",XF86AudioPlay,exec, playerctl play-pause"
            ",XF86AudioNext,exec, playerctl next"
            ",XF86AudioPrev,exec, playerctl previous"
            ",XF86AudioStop, exec, playerctl stop"
            "$mod, mouse_down, workspace, e-1"
            "$mod, mouse_up, workspace, e+1"

            # laptop brigthness
            ",XF86MonBrightnessUp, exec, ${brightnessctl}/bin/brightnessctl set 5%+"
            ",XF86MonBrightnessDown, exec, ${brightnessctl}/bin/brightnessctl set 5%-"
            "$mod, XF86MonBrightnessUp, exec, ${brightnessctl}/bin/brightnessctl set 100%+"
            "$mod, XF86MonBrightnessDown, exec, ${brightnessctl}/bin/brightnessctl set 100%-"

            # clipboard manager
            "$mod, V, exec, ${cliphist}/bin/cliphist list | ${wofi}/bin/wofi --dmenu | ${cliphist}/bin/cliphist decode | ${wl-clipboard-rs}/bin/wl-copy"
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
            layout = "master"; # master | dwindle
            gaps_in = 0;
            gaps_out = 0;
            border_size = 2;
            "col.active_border" = "rgb(cba6f7) rgb(94e2d5) 45deg";
            "col.inactive_border" = "0x00000000";
            border_part_of_window = false;
            no_border_on_floating = false;

          };
          decoration = {
            rounding = 5;

            blur = {
              enabled = true;
              size = 1;
              passes = 1;
              brightness = 1;
              contrast = 1.4;
              ignore_opacity = true;
              noise = 0;
              new_optimizations = true;
              xray = true;
            };

            drop_shadow = true;

            shadow_ignore_window = true;
            shadow_offset = "0 2";
            shadow_range = 20;
            shadow_render_power = 3;
            "col.shadow" = "rgba(00000055)";
          };

          animations = {
            enabled = true;

            bezier = [
              "fluent_decel, 0, 0.2, 0.4, 1"
              "easeOutCirc, 0, 0.55, 0.45, 1"
              "easeOutCubic, 0.33, 1, 0.68, 1"
              "easeinoutsine, 0.37, 0, 0.63, 1"
            ];

            animation = [
              # Windows
              "windowsIn, 1, 3, easeOutCubic, popin 30%" # window open
              "windowsOut, 1, 3, fluent_decel, popin 70%" # window close.
              "windowsMove, 1, 2, easeinoutsine, slide" # everything in between, moving, dragging, resizing.

              # Fade
              "fadeIn, 1, 3, easeOutCubic" # fade in (open) -> layers and windows
              "fadeOut, 1, 2, easeOutCubic" # fade out (close) -> layers and windows
              "fadeSwitch, 0, 1, easeOutCirc" # fade on changing activewindow and its opacity
              "fadeShadow, 1, 10, easeOutCirc" # fade on changing activewindow for shadows
              "fadeDim, 1, 4, fluent_decel" # the easing of the dimming of inactive windows
              "border, 1, 2.7, easeOutCirc" # for animating the border's color switch speed
              "borderangle, 1, 30, fluent_decel, once" # for animating the border's gradient angle - styles: once (default), loop
              "workspaces, 1, 4, easeOutCubic, fade" # styles: slide, slidevert, fade, slidefade, slidefadevert
            ];
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
            mouse_move_enables_dpms = true;
          };
        };
      };
    };

    user.packages = with pkgs; [
      cliphist

      egl-wayland
      eglexternalplatform
      libglvnd

      imv
      libnotify

      mako
      man-pages
      networkmanagerapplet

      cinnamon.nemo-with-extensions

      pamixer
      pavucontrol
      playerctl
      poweralertd

      wf-recorder
      wlr-randr
      # wallpapers

      hyprpaper
      swaybg
      swaylock-effects
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

      wl-clipboard-rs
      wl-clip-persist

    ];

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
