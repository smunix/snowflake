{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.editors.emacs;
  configDir = config.snowflake.configDir;
in {
  options.modules.desktop.editors.emacs = {
    enable = mkBoolOpt false;
    doom = rec {
      enable = mkBoolOpt false;
      forgeUrl = mkOpt types.str "https://github.com";
      repoUrl = mkOpt types.str "${forgeUrl}/doomemacs/doomemacs";
      configRepoUrl = mkOpt types.str "${forgeUrl}/icy-thought/emacs.d";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [inputs.emacs.overlay];

    hm.services.emacs = {
      enable = true;
      client.enable = true;
    };

    hm.programs.emacs = {
      enable = true;
      package = pkgs.emacsNativeComp;
      extraPackages = epkgs: with epkgs; [vterm];
    };

    user.packages = [
      pkgs.binutils
      pkgs.gnutls
      pkgs.zstd
      (mkIf config.programs.gnupg.agent.enable [pkgs.pinentry_emacs])
    ];

    # Fonts -> icons + ligatures when specified:
    fonts.fonts = [pkgs.emacs-all-the-icons-fonts];

    # Enable access to doom (tool).
    env.PATH = ["$XDG_CONFIG_HOME/emacs/bin"];

    environment.variables = {
      EMACSDIR = "$XDG_CONFIG_HOME/emacs";
      DOOMDIR = "${configDir}/emacs.d/doom-emacs";
    };

    system.userActivationScripts = mkIf cfg.doom.enable {
      installDoomEmacs = ''
        if [ ! -d "$XDG_CONFIG_HOME/emacs" ]; then
           git clone --depth=1 --single-branch "${cfg.doom.repoUrl}" "$XDG_CONFIG_HOME/emacs"
           git clone "${cfg.doom.configRepoUrl}" "$XDG_CONFIG_HOME/doom"
        fi
      '';
    };

    # Allow fish-shell to send information to vterm via properly escaped sequences.
    hm.programs.fish = {
      interactiveShellInit = ''
        function vterm_printf;
            if begin; [  -n "$TMUX" ]  ; and  string match -q -r "screen|tmux" "$TERM"; end
                # tell tmux to pass the escape sequences through
                printf "\ePtmux;\e\e]%s\007\e\\" "$argv"
            else if string match -q -- "screen*" "$TERM"
                # GNU screen (screen, screen-256color, screen-256color-bce)
                printf "\eP\e]%s\007\e\\" "$argv"
            else
                printf "\e]%s\e\\" "$argv"
            end
        end
      '';

      # Easier frame creation (fish)
      functions = {
        eg = "emacs --create-frame $argv & disown";
        ecg = "emacsclient --create-frame $argv & disown";
      };
    };
  };
}
