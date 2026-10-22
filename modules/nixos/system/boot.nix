{lib, ...}: {
  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        # Prevent boot-menu edits such as init=/bin/sh.
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
