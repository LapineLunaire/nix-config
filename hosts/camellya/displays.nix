{pkgs, ...}: let
  kwinOutputConfig = let
    # Both panels: 4K, 160 Hz, 1.25x scale, HDR.
    panel = {
      abmLevel = 0;
      allowDdcCi = true;
      allowSdrSoftwareBrightness = true;
      autoRotation = "InTabletMode";
      automaticBrightness = false;
      brightness = 1;
      colorPowerTradeoff = "PreferAccuracy";
      customModes = [];
      edrPolicy = "always";
      hdrColorProfileSource = "EDID";
      highDynamicRange = true;
      mode = {
        flags = 0;
        height = 2160;
        refreshRate = 160000;
        width = 3840;
      };
      overscan = 0;
      rgbRange = "Automatic";
      scale = 1.25;
      # Use the same SDR white level on both panels.
      sdrBrightness = 486;
      sdrGamutWideness = 1;
      sharpness = 0;
      vrrPolicy = "Automatic";
      wideColorGamut = true;
    };

    # Primary landscape panel.
    dp3 =
      panel
      // {
        colorProfileSource = "sRGB";
        connectorName = "DP-3";
        edidHash = "d1af945b1652fada5e66f1255a067bbf";
        edidIdentifier = "SKG 10100 0 26 2025 0";
        maxPeakBrightnessOverride = 1405;
        transform = "Normal";
      };

    # Portrait panel: 1728x3072 logical pixels.
    dp2 =
      panel
      // {
        colorProfileSource = "EDID";
        connectorName = "DP-2";
        edidHash = "713337e9a897a5cf035b654c2fd45fb5";
        edidIdentifier = "SKG 10104 0 30 2025 0";
        transform = "Rotated90";
      };

    # Positions use logical pixels; outputIndex refers to the list below.
    setups = [
      {
        lidClosed = false;
        outputs = [
          {
            enabled = true;
            outputIndex = 0;
            position = {
              x = 0;
              y = 0;
            };
            priority = 1;
            replicationSource = "";
          }
        ];
      }
      {
        lidClosed = false;
        outputs = [
          {
            enabled = true;
            outputIndex = 1;
            position = {
              x = 3072;
              y = 0;
            };
            priority = 2;
            replicationSource = "";
          }
          # Align the panels at eye level.
          {
            enabled = true;
            outputIndex = 0;
            position = {
              x = 0;
              y = 550;
            };
            priority = 1;
            replicationSource = "";
          }
        ];
      }
      {
        lidClosed = false;
        outputs = [
          {
            enabled = true;
            outputIndex = 1;
            position = {
              x = 0;
              y = 0;
            };
            priority = 1;
            replicationSource = "";
          }
        ];
      }
    ];
  in
    pkgs.writeText "kwinoutputconfig.json" (builtins.toJSON [
      {
        data = [dp3 dp2];
        name = "outputs";
      }
      {
        data = setups;
        name = "setups";
      }
    ]);
in {
  # Give the greeter the same layout as the user session.
  systemd.tmpfiles.settings."10-plasma-login-displays" = {
    "/var/lib/plasmalogin/.config".d = {
      mode = "0750";
      user = "plasmalogin";
      group = "plasmalogin";
    };
    "/var/lib/plasmalogin/.config/kwinoutputconfig.json"."L+".argument = "${kwinOutputConfig}";
  };

  # Keep this writable for System Settings. A rebuild restores the declared layout.
  home-manager.users.carmilla = {lib, ...}: {
    home.activation.kwinOutputConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run install -Dm644 ${kwinOutputConfig} "$HOME/.config/kwinoutputconfig.json"
    '';
  };
}
