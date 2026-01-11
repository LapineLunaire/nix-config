{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor.overrideAttrs (oldAttrs: {doCheck = false;});
    userSettings = {
      telemetry.metrics = false;
      load_direnv = "shell_hook";
      vim_mode = true;
      hour_format = "hour24";
    };
    extensions = [
      "nix"
    ];
  };
}
