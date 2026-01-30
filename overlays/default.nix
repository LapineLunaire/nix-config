{...}: {
  # This overlay adds our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This overlay can be used to modify or add custom versions of packages
  modifications = _final: _prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };
}
