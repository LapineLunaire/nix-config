{
  pkgs,
  extraSubstituters,
  extraTrustedPublicKeys,
}: let
  inherit (pkgs) lib;
  tools = pkgs.buildEnv {
    name = "ci-tools";
    paths = with pkgs; [
      attic-client
      bash
      coreutils
      diffutils
      gitMinimal
      gnugrep
      gnused
      nix
      nodejs
      openssh
      skopeo
    ];
    pathsToLink = ["/bin"];
  };
  nixConfig = pkgs.writeTextDir "etc/nix/nix.conf" ''
    experimental-features = nix-command flakes
    flake-registry =
    fallback = true
    max-jobs = 3
    # The Nix sandbox needs privileges the job container lacks; the container isolates builds instead.
    sandbox = false
    build-users-group =
    extra-substituters = ${lib.concatStringsSep " " extraSubstituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " extraTrustedPublicKeys}
    netrc-file = /etc/nix/netrc
  '';
in
  pkgs.dockerTools.buildLayeredImage {
    name = "localhost/nix-ci";
    # The runner registers again whenever its labels change, so the tag stays fixed.
    tag = "current";
    includeNixDB = true;
    contents = [
      tools
      nixConfig
      pkgs.dockerTools.binSh
      pkgs.dockerTools.caCertificates
      pkgs.dockerTools.fakeNss
    ];
    extraCommands = ''
      mkdir -p tmp root
      chmod 1777 tmp
    '';
    config = {
      Env = [
        "PATH=/bin"
        "HOME=/root"
        "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
      ];
    };
  }
