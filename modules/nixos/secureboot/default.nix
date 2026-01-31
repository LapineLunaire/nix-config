{
  pkgs,
  lib,
  config,
  ...
}: {
  options.secureboot = {
    enable = lib.mkEnableOption "Enable Secure Boot with Lanzaboote";
  };

  config = lib.mkIf config.secureboot.enable {
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    environment.systemPackages = with pkgs; [
      sbctl
      tpm2-tools
    ];

    boot.initrd.systemd.enable = true;
    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
