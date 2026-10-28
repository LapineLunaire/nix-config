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
  # One build user per concurrent build.
  maxJobs = 3;
  buildUsers = map (n: "nixbld${toString n}") (lib.range 1 maxJobs);
  nss = pkgs.dockerTools.fakeNss.override {
    extraPasswdLines = lib.imap1 (n: user: "${user}:x:${toString (30000 + n)}:30000:Nix build user:/var/empty:/noshell") buildUsers;
    extraGroupLines = ["nixbld:x:30000:${lib.concatStringsSep "," buildUsers}"];
  };
  nixConfig = pkgs.writeTextDir "etc/nix/nix.conf" ''
    experimental-features = nix-command flakes
    flake-registry =
    fallback = true
    max-jobs = ${toString maxJobs}
    # The Nix sandbox needs privileges the job container lacks; the container isolates builds instead.
    sandbox = false
    # Root builders can create /homeless-shelter, and unsandboxed Nix then refuses to build.
    build-users-group = nixbld
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
      nss
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
