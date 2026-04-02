{
  config,
  lib,
  pkgs,
  ...
}: {
  options.secureboot = {
    enable = lib.mkEnableOption "Secure Boot with Lanzaboote";
  };

  config = lib.mkIf config.secureboot.enable {
    # pkiBundle stores the Secure Boot signing keys.
    # On impermanence hosts, /var/lib/sbctl must be listed in environment.persistence and pre-created via tmpfiles (see each host's tmpfiles.nix).
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    environment.systemPackages = with pkgs; [
      sbctl
      tpm2-tools
    ];

    # tctiEnvironment sets TPM2TOOLS_TCTI so tpm2-tools commands work without explicitly specifying a TCTI string.
    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
