{...}: {
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "zha"
    ];
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        temperature_unit = "C";
      };
      http = {
        server_port = 7000;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      default_config = {};
    };
  };
}
