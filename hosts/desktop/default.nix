{
  inputs,
  ...
}: {
  imports = [
    ./programs.nix
    ./security.nix
    ./services.nix
    ./stylix.nix
  ];

  config = {
    home-manager.users.lapine.userConfig.desktop.enable = true;

    boot.kernelModules = ["ntsync"];

    nix.settings = inputs.aagl.nixConfig;

    console.keyMap = "colemak";

    environment.sessionVariables = {
      PROTON_ENABLE_WAYLAND = "1";
      PROTON_ENABLE_HDR = "1";
      FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
    };

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
  };
}
