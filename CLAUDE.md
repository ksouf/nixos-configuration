# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS configuration repository for a Dell XPS 13-9370 developer workstation. The system uses declarative configuration with modular organization.

## Build Commands

```bash
# Apply configuration changes
sudo nixos-rebuild switch

# Test changes without making permanent
sudo nixos-rebuild test

# Build without activating
sudo nixos-rebuild build

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## Architecture

### Entry Point
- `configuration.nix` - Main configuration that imports all modules

### Module Organization

| Directory | Purpose |
|-----------|---------|
| `modules/` | Core system modules (security hardening) |
| `desktop/` | Desktop environments (GNOME active, i3/Hyprland alternatives) |
| `devices/` | Hardware configs (audio, bluetooth, network, keyboards, LUKS encryption) |
| `shell/` | Shell environment (Zsh with Oh-My-Zsh, Tilix terminal) |
| `home-manager-target/` | User applications organized by category |

### Key Hardware Files
- `hardware.nix` - Hardware optimizations (Intel microcode, TLP, fstrim, zram)
- `hardware-configuration.nix` - Auto-generated, do not edit manually

### Home Manager Target Structure
- `developer-tools/` - IDEs, SDKs, virtualization (Docker, K8s), VCS
- `documents-mgt/` - LibreOffice, LaTeX
- `security/` - 1Password
- `social/` - Slack, Discord, Zoom, Spotify
- `browsers.nix` - Chrome, Brave

### Key Files
- `hardware.nix` - Hardware optimizations (Intel CPU, TLP power management, fstrim)
- `modules/security.nix` - Security hardening (firewall, SSH, kernel)
- `system-packages.nix` - System-wide packages and modern CLI tools
- `users.nix` - User account configuration (user: khaled)

## Package Management Pattern

The configuration uses two channels:
- **stable** (default `pkgs`) - Base system packages
- **unstable** - Newer versions for frequently-updated apps

To use unstable packages in a module:
```nix
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  environment.systemPackages = with pkgs; [
    stable-package
    unstable.newer-package
  ];
}
```

## Adding New Configurations

### New Application
1. Create or edit appropriate file in `home-manager-target/`
2. Import it in `configuration.nix`
3. Run `sudo nixos-rebuild switch`

### New Module Pattern
```nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    package-name
  ];
}
```

## System Details

- **Hostname:** hanibal
- **User:** khaled (UID 1000, groups: wheel, docker, networkmanager)
- **Locale:** fr_FR.UTF-8
- **Timezone:** Europe/Paris
- **Keyboard:** French BÉPO layout (ergonomic)

## Required Channels

```bash
# Hardware-specific configurations
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware

# Unstable channel for newer packages
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable

sudo nix-channel --update
```
