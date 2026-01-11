{pkgs, ...}: {
  users.users.lapine = {
    isNormalUser = true;
    description = "Lapine";
    shell = pkgs.zsh;
    # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
    hashedPassword = "$6$h.m1Ftri0Zjsinfs$jKmYsiTrcWzTOCVGSeKA53p/1twd0buX/qxzS08aB6Dgm7PVl9jQTeiZEmb4MIBWrZHEsyLt/ejQsko4b.abf/";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    # FIDO2 hardware key
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU="
    ];
  };
}
