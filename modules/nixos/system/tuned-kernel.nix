{
  config,
  lib,
  ...
}: let
  cfg = config.host.kernel;
in {
  options.host.kernel = {
    packages = lib.mkOption {
      type = lib.types.raw;
      description = "Kernel package set to tune.";
    };
    cpu = lib.mkOption {
      type = lib.types.str;
      description = "Explicit CPU target for kernel C and Rust compilation.";
    };
  };

  config.boot.kernelPackages = cfg.packages.extend (_: prev: {
    kernel = prev.kernel.override {
      # Keep each flag one shell word. Override generic C tuning and set Rust's target too.
      extraMakeFlags = [
        "KCFLAGS=-march=${cfg.cpu}"
        "CFLAGS_KERNEL=-mtune=${cfg.cpu}"
        "CFLAGS_MODULE=-mtune=${cfg.cpu}"
        "KRUSTFLAGS=-Ctarget-cpu=${cfg.cpu}"
      ];
    };
  });
}
