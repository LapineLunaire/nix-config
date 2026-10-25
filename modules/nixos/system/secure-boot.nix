{
  config,
  lib,
  pkgs,
  ...
}: let
  measuredUnlock = lib.any (device: lib.elem "tpm2-measure-pcr=yes" device.crypttabExtraOpts) (lib.attrValues config.boot.initrd.luks.devices);
in {
  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Unlocking with tpm2-measure-pcr=yes measures the volume through this socket. NixOS includes it in the initrd but never starts it.
  # Nothing else starts cryptsetup-pre.target, so the socket starts it itself to be ready before the first unlock.
  boot.initrd.systemd.sockets.systemd-pcrextend = lib.mkIf measuredUnlock {
    wantedBy = ["cryptsetup.target"];
    wants = ["cryptsetup-pre.target"];
    before = ["cryptsetup-pre.target"];
  };

  environment.systemPackages = with pkgs; [
    sbctl
    tpm2-tools
  ];

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
}
