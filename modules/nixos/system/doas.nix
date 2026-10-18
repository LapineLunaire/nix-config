{pkgs, ...}: {
  security.doas = {
    enable = true;
    extraRules = [
      {
        groups = ["wheel"];
        persist = true;
      }
    ];
  };

  # Provide a sudo command for tools that expect it.
  environment.systemPackages = [pkgs.doas-sudo-shim];
}
