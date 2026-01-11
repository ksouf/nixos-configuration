# NixOS Upgrades and Version Management

## Trigger
Upgrading NixOS versions, switching channels, or managing flake inputs.

## Overview

NixOS upgrade methods:

| Method | Use Case | Rollback |
|--------|----------|----------|
| Channel-based | Traditional, non-flake | Easy |
| Flake inputs | Modern, reproducible | Easy |
| In-place upgrade | Major version | Easy |

---

## Understanding Versions

### NixOS Releases

| Channel | Description | Updates |
|---------|-------------|---------|
| `nixos-24.11` | Stable release | Security + bug fixes |
| `nixos-unstable` | Rolling release | Frequent |
| `nixos-24.11-small` | Stable, fewer binaries | Faster updates |
| `nixos-unstable-small` | Unstable, fewer binaries | Fastest |

### Checking Current Version

```bash
# NixOS version
nixos-version
# 24.11.20240115.abc1234 (Vicuna)

# Nix version
nix --version

# Current generation
nixos-rebuild list-generations | head -5
```

---

## Flake-Based Upgrades (Recommended)

### Updating Flake Inputs

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Update to specific commit
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/abc123
```

### Switching Nixpkgs Version

```nix
# flake.nix
{
  inputs = {
    # Stable 24.11
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Or unstable
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Or specific commit
    # nixpkgs.url = "github:NixOS/nixpkgs/abc123456789";

    # Match home-manager to nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### Major Version Upgrade (Flakes)

```bash
# 1. Edit flake.nix to new version
# nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
# becomes
# nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

# 2. Update home-manager to match
# home-manager.url = "github:nix-community/home-manager/release-25.05";

# 3. Update lock file
nix flake update

# 4. Build first (don't switch yet)
nixos-rebuild build --flake .#myhost

# 5. Check for issues
nvd diff /run/current-system result

# 6. Review release notes
# https://nixos.org/manual/nixos/stable/release-notes.html

# 7. Apply
sudo nixos-rebuild switch --flake .#myhost
```

---

## Channel-Based Upgrades (Legacy)

### Listing Channels

```bash
# Show current channels
sudo nix-channel --list

# Example output:
# nixos https://nixos.org/channels/nixos-24.11
```

### Switching Channels

```bash
# Switch to new stable
sudo nix-channel --add https://nixos.org/channels/nixos-25.05 nixos

# Or to unstable
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos

# Update channel data
sudo nix-channel --update

# Apply changes
sudo nixos-rebuild switch --upgrade
```

### Auto-Upgrade

```nix
# configuration.nix
{
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;  # Don't reboot automatically

    # For channels
    channel = "https://nixos.org/channels/nixos-24.11";

    # For flakes
    flake = "/etc/nixos#myhost";

    # Schedule
    dates = "04:00";  # Daily at 4 AM

    # Options
    flags = [
      "--update-input" "nixpkgs"
    ];
  };
}
```

---

## Before Upgrading

### Check Release Notes

```bash
# Open release notes in browser
xdg-open https://nixos.org/manual/nixos/stable/release-notes.html

# Or for unstable
xdg-open https://nixos.org/manual/nixos/unstable/release-notes.html
```

### Check for Deprecated Options

```bash
# Build and look for warnings
nixos-rebuild build --flake .#myhost 2>&1 | grep -i deprecat

# Check nixpkgs changelog
nix log nixpkgs#somePackage
```

### Backup Current State

```bash
# List generations
nixos-rebuild list-generations

# Current system link
ls -la /run/current-system

# Keep at least 2-3 generations
sudo nix-collect-garbage --delete-older-than 7d
```

---

## Performing the Upgrade

### Standard Upgrade

```bash
# 1. Update inputs/channels
nix flake update
# or
sudo nix-channel --update

# 2. Build first
nixos-rebuild build --flake .#myhost

# 3. Check diff
nvd diff /run/current-system result

# 4. Test (activate but don't add boot entry)
sudo nixos-rebuild test --flake .#myhost

# 5. Verify system works

# 6. Full switch
sudo nixos-rebuild switch --flake .#myhost
```

### Upgrade with Dry Run

```bash
# See what would change
nixos-rebuild dry-activate --flake .#myhost 2>&1 | less
```

---

## Rollback

### Immediate Rollback

```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or to specific generation
sudo nixos-rebuild switch --generation 42
```

### Boot Menu Rollback

If system won't boot:
1. Reboot
2. In boot menu, select older generation
3. System boots with old config
4. Fix issues and rebuild

### List Available Generations

```bash
# List all generations
nixos-rebuild list-generations

# Detailed info
nix-env --list-generations --profile /nix/var/nix/profiles/system
```

---

## Mixed Stable/Unstable

Use stable base with select unstable packages.

### Flake Method

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, nixpkgs-unstable, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        pkgs-unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
      modules = [ ./configuration.nix ];
    };
  };
}
```

```nix
# configuration.nix
{ pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs.vim                    # From stable
    pkgs-unstable.firefox       # From unstable
    pkgs-unstable.vscode        # From unstable
  ];
}
```

### Overlay Method

```nix
# flake.nix
{
  outputs = { nixpkgs, nixpkgs-unstable, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
              unstable = import nixpkgs-unstable {
                system = prev.system;
                config.allowUnfree = true;
              };
            })
          ];
        }
        ./configuration.nix
      ];
    };
  };
}
```

```nix
# configuration.nix
{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.vim              # Stable
    pkgs.unstable.firefox # Unstable via overlay
  ];
}
```

---

## Troubleshooting Upgrades

### Build Failures

```bash
# Get detailed error
nixos-rebuild build --flake .#myhost 2>&1 | less

# Check specific package
nix build nixpkgs#problematic-package -L

# Try with more memory
NIX_BUILD_CORES=1 nixos-rebuild build --flake .#myhost
```

### Deprecated Options

```nix
# Common migrations

# sound.enable (removed)
# Just remove it, ALSA is enabled by default

# hardware.pulseaudio.enable → services.pipewire
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
};

# services.xserver.layout → services.xserver.xkb.layout
services.xserver.xkb.layout = "us";
```

### Service Failures After Upgrade

```bash
# Check service status
systemctl status problematic.service

# Check logs
journalctl -u problematic.service -n 50

# Check what changed in service
diff /run/booted-system/etc/systemd/system/problematic.service \
     /run/current-system/etc/systemd/system/problematic.service
```

### Kernel Issues

```bash
# Boot with old kernel from boot menu

# Check available kernels
ls /nix/var/nix/profiles/system-*/kernel

# Pin kernel version
boot.kernelPackages = pkgs.linuxPackages_6_6;
```

---

## Garbage Collection

### After Upgrade

```bash
# Remove old generations (keep last 5)
sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system

# Collect garbage
sudo nix-collect-garbage

# More aggressive (removes all old generations)
sudo nix-collect-garbage -d
```

### Automated GC

```nix
{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Also optimize store
  nix.optimise.automatic = true;
}
```

---

## Version Pinning

### Pin Specific Package

```nix
# Pin from specific nixpkgs commit
{
  environment.systemPackages = [
    (import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/abc123.tar.gz";
      sha256 = "sha256-...";
    }) {}).specificPackage
  ];
}
```

### Pin in Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Specific package from older nixpkgs
    nixpkgs-python39.url = "github:NixOS/nixpkgs/abc123";
  };
}
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Check version | `nixos-version` |
| Update flake | `nix flake update` |
| Update channel | `sudo nix-channel --update` |
| Build only | `nixos-rebuild build` |
| Test switch | `nixos-rebuild test` |
| Full switch | `nixos-rebuild switch` |
| Rollback | `nixos-rebuild switch --rollback` |
| List generations | `nixos-rebuild list-generations` |
| Clean up | `nix-collect-garbage -d` |

## Confidence
1.0 - Core NixOS upgrade procedures from official documentation.

## Sources
- [NixOS Manual - Upgrading](https://nixos.org/manual/nixos/stable/#sec-upgrading)
- [NixOS Release Notes](https://nixos.org/manual/nixos/stable/release-notes.html)
- [Nix Channels](https://nixos.wiki/wiki/Nix_channels)
