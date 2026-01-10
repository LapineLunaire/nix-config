{pkgs, ...}: {
  users.users.lapine = {
    isNormalUser = true;
    description = "Lapine";
    shell = pkgs.zsh;
    initialPassword = "usagi";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
    # FIDO2 hardware key
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEes6fnuE4zIKuneekCyPzMYItOOgfnDo0Eiakvwf62mAAAACnNzaDpsYXBpbmU="
    ];
  };
}
