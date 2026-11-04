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

  # Unlocks with tpm2-measure-pcr=yes need this socket, which NixOS puts in the initrd but never starts.
  # Nothing else starts cryptsetup-pre.target, so the socket pulls it in.
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
