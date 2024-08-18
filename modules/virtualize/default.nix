{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (builtins) isAttrs;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.my) anyAttrs countAttrs value;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) nullOr enum;

  cfg = config.modules.virtualize;
in
{
  options.modules.virtualize = {
    enable = mkOption {
      type = nullOr (enum [
        "none"
        "vbox"
        "qemu"
      ]);
      description = "Spawn virtual environements where required";
      default = "none";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable == "vbox") {
      virtualisation = {
        virtualbox.host = {
          enable = true;
          enableExtensionPack = true;
        };
      };
      users.extraGroups.vboxusers.members = [ "${config.user.name}" ];
    })
    (mkIf (cfg.enable == "qemu") {
      user.packages = attrValues {
        inherit (pkgs)
          virt-manager
          virt-viewer
          win-virtio
          spice
          spice-gtk
          spice-protocol
          win-spice
          ;
      };

      virtualisation = {
        libvirtd = {
          enable = true;
          # extraOptions = ["--verbose"];
          qemu.ovmf = {
            enable = true;
            packages = [ pkgs.OVMFFull.fd ];
          };
        };
        spiceUSBRedirection.enable = true;
      };
      user.extraGroups = [ "libvirtd" ];

      services.spice-vdagentd.enable = true;

      # Fix: Could not detect a default hypervisor. Make sure the appropriate QEMU/KVM virtualization...
      hm.dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    })
  ];
}
