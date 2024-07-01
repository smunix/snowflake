{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption;

  active = config.modules.themes.active;
in
{
  options.modules.desktop.terminal.rio = {
    enable = mkEnableOption "A Rust/WebGPU based terminal emulator.";
  };

  config = mkIf config.modules.desktop.terminal.rio.enable {
    modules.shell.toolset.tmux.enable = false;

    hm.programs.rio = {
      enable = true;

      settings = mkMerge [
        {
          # env-vars = {
          #   # TERM = "xterm-256color";
          #   TERM = "wezterm";
          # };

          cursor = "▇";

          blinking-cursor = true;
          # editor = "emacsclient -c";
          editor = "emacs -nw";
          padding-x = 10;

          renderer = {
            backend = "Automatic";
            performance = "High";
            disable-renderer-when-unfocused = true;
          };

          keyboard = {
            use-kitty-keyboard-protocol = true;
            disable-ctlseqs-alt = false;
          };

          navigation = {
            mode = "CollapsedTab";
            clickable = true;
            use-current-path = true;
            color-automation = [ ];
          };

          scroll = {
            multiplier = 3.0;
            divider = 1.0;
          };

          window = {
            mode = "Windowed";
            background-opacity = 0.9;
            foreground-opacity = 1.0;
            blur = true;
          };
        }

        (mkIf (active != null) {
          fonts =
            let
              inherit (config.modules.themes.font.mono) family size weightNum;
            in
            {
              family = "${family}";
              size = size + 1;

              # extras = [{family = "";}];

              regular = {
                family = "${family}";
                style = "normal";
                weight = weightNum;
              };
              bold = {
                family = "${family}";
                style = "normal";
                weight = weightNum + 100;
              };
              italic = {
                family = "${family}";
                style = "italic";
                weight = weightNum;
              };
              bold-italic = {
                family = "${family}";
                style = "italic";
                weight = weightNum + 100;
              };
            };

          theme = "${active}";
        })
      ];
    };

    home.configFile = mkIf (active != null) {
      alacritty-conf = {
        target = "rio//themes/${active}.toml";
        source =
          let
            inherit (config.modules.themes.colors.main) bright normal types;
            tomlFormat = pkgs.formats.toml { };
          in
          tomlFormat.generate "theme-spec" {
            colors = {
              foreground = "${types.fg}";
              background = "${types.bg}";

              cursor = "${normal.yellow}";
              tabs = "${types.bg}";
              tabs-active = "${types.border}";
              selection-foreground = "${types.highlight}";
              selection-background = "${types.bg}";

              black = "${normal.black}";
              red = "${normal.red}";
              green = "${normal.green}";
              yellow = "${normal.yellow}";
              blue = "${normal.blue}";
              magenta = "${normal.magenta}";
              cyan = "${normal.cyan}";
              white = "${normal.white}";

              dim-black = "${bright.black}";
              dim-red = "${bright.red}";
              dim-green = "${bright.green}";
              dim-yellow = "${bright.yellow}";
              dim-blue = "${bright.blue}";
              dim-magenta = "${bright.magenta}";
              dim-cyan = "${bright.cyan}";
              dim-white = "${bright.white}";

              light-black = "${bright.black}";
              light-red = "${bright.red}";
              light-green = "${bright.green}";
              light-yellow = "${bright.yellow}";
              light-blue = "${bright.blue}";
              light-magenta = "${bright.magenta}";
              light-cyan = "${bright.cyan}";
              light-white = "${bright.white}";
            };
          };
      };
    };
  };
}
