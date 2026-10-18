# Install Silverwolf

Silverwolf uses the existing `carmilla` account at `/Users/carmilla` on Apple Silicon. Nix and Home Manager provide the shared desktop programs, IINA, mtr, and UTM. [Homebrew](../modules/darwin/homebrew.nix) manages the other applications, including all three Proton apps and the Mac App Store list.

Install [Homebrew](https://brew.sh/) and sign in to the Mac App Store before switching. The `container` formula requires [macOS 26 or later](https://formulae.brew.sh/formula/container). Grant the terminal App Management permission if macOS requests it while installing applications.

Activation updates Homebrew, upgrades installed applications, and removes unlisted formulae and casks.

Nix cleanup runs daily with `nh clean all --keep 3`, keeping at least three generations per profile.

Install multi-user Nix first and confirm `nix --version` works in a new terminal. Replace `<repo>` with this repository's clone URL:

```sh
mkdir -p ~/projects
git clone <repo> ~/projects/nix-config
cd ~/projects/nix-config
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from . nix-darwin#darwin-rebuild \
  -- switch --flake .#silverwolf
```

The first switch uses the checkout's pinned nix-darwin. Later, run `nh darwin switch .` from the checkout. To recover, restore user data and reapply the configuration.

Restore the [YubiKey SSH and Git signing identity](keys.md#yubikey-ssh-and-git-signing) before using SSH or signing commits.
