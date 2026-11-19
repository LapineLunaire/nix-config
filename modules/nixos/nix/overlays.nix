# Every NixOS host and guest applies the same overlays, so they cannot drift apart.
{nixpkgs.overlays = with import ../../../overlays; [additions modifications];}
