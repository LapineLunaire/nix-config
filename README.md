# nix-config

## Hosts

| Host | Platform | Role |
|------|----------|------|
| camellya | x86_64-linux | Desktop |
| sparkle | x86_64-linux | Home server |
| sparxie | aarch64-linux | VPS |
| silverwolf | aarch64-darwin | MacBook |

Linux hosts use impermanence with tmpfs `/` — state persists only through explicitly declared paths. Secrets are sops-nix encrypted to each host's SSH ed25519 host key.

## Structure

```
hosts/          Per-host hardware, services, secrets, persistence declarations
modules/
  darwin/       macOS system defaults, firewall, privacy settings
  nixos/
    generic/    Base NixOS: kernel hardening, SSH, ZFS, zram, chrony
    desktop/    Hyprland, PipeWire, fonts, Stylix theming, Steam
    secureboot/ Lanzaboote secure boot
users/carmilla/ home-manager: shell, git, neovim, SSH, desktop environment
pkgs/           Custom derivations
overlays/       ffmpeg unfree codecs, protonmail-desktop X11 ozone workaround
```

## Implementation notes

- qBittorrent on sparkle runs in a VPN-Confinement network namespace (ProtonVPN)
- Ghostty on macOS: installed via homebrew cask (no darwin support in nixpkgs), configured via home-manager with `package = null`
- Hyprland mod key is ALT with remapped macOS-style shortcuts (ALT+C/V → CTRL+C/V via `sendshortcut`)
- protonmail-desktop overlay forces X11 ozone platform on Linux to avoid Wayland crashes
- Console keymap is Colemak on all Linux hosts

## Manual post-install steps

- Export FIDO2 resident SSH keys from YubiKey: `ssh-keygen -K` in `~/.ssh/`
- Create `~/Pictures/Screenshots` on macOS
- Grant App Management permission to the terminal emulator (System Settings → Privacy & Security → App Management)

## Usage

```sh
# NixOS
nh os switch .

# macOS
nh darwin switch .
```
