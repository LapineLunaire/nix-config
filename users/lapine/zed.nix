{
  pkgs,
  inputs,
  ...
}: {
  programs.zed-editor = {
    enable = true;

    userSettings = {
      telemetry.metrics = false;
      load_direnv = "shell_hook";
      vim_mode = true;
      hour_format = "hour24";
      lsp.nixd.settings.nixpkgs.expr = "import <nixpkgs> {}";
    };
    extensions = [
      "nix"
    ];
  };

  home.packages = [
    inputs.nixd.packages.${pkgs.system}.nixd
  ];
}
