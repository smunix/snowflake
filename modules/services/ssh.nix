{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) filter pathExists;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.meta) getExe getExe';
in
{
  options.modules.services.ssh = {
    enable = mkEnableOption "secure-socket shell";
  };

  config = mkIf config.modules.services.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };

      hostKeys = [
        {
          comment = "${config.user.home}";
          path = "/etc/ssh/ed25519_key";
          rounds = 100;
          type = "ed25519";
        }
      ];
    };

    systemd.user.services.ssh-agent = {
      description = "SSH key agent";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        Environment = [
          "DISPLAY=:0"
          "SSH_AUTH_SOCK=%t/ssh-agent.socket"
        ];
        ExecStart = ''${getExe' pkgs.openssh "ssh-agent"} -D -a $SSH_AUTH_SOCK'';
      };
    };

    user.openssh.authorizedKeys.keyFiles =
      if config.user.name == "smunix" then
        filter pathExists [
          "${config.user.home}/.ssh/id_ed25519.pub"
          "${config.user.home}/.ssh/id_rsa.pub"
        ]
      else
        [ ];
  };
}
