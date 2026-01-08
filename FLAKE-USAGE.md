# NixOS Flake Usage Guide

This system has been migrated to use Nix Flakes for better reproducibility and dependency management.

## Quick Reference

### Rebuild System (Most Common)

```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake /etc/nixos#hanibal

# Test changes without making permanent
sudo nixos-rebuild test --flake /etc/nixos#hanibal

# Build without activating
sudo nixos-rebuild build --flake /etc/nixos#hanibal

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

### Update Packages

```bash
# Update all flake inputs (nixpkgs, nixos-hardware, etc.)
cd /etc/nixos && nix flake update

# Update only nixpkgs-unstable
cd /etc/nixos && nix flake lock --update-input nixpkgs-unstable

# Then rebuild to apply updates
sudo nixos-rebuild switch --flake /etc/nixos#hanibal
```

### First-Time Setup

On first flake build, dependencies will be downloaded (~500MB). This is normal:

```bash
# Generate lock file (pins all dependency versions)
cd /etc/nixos && nix flake lock

# Build with flake
sudo nixos-rebuild switch --flake /etc/nixos#hanibal
```

## Flake vs Channels Comparison

| Task | Channels (Old) | Flakes (New) |
|------|----------------|--------------|
| Rebuild | `sudo nixos-rebuild switch` | `sudo nixos-rebuild switch --flake /etc/nixos#hanibal` |
| Update packages | `sudo nix-channel --update` | `cd /etc/nixos && nix flake update` |
| Check versions | `nix-channel --list` | `nix flake metadata` |
| Reproducibility | Versions drift | Versions pinned in `flake.lock` |

## Key Files

- `flake.nix` - Flake definition with inputs (nixpkgs, nixos-hardware)
- `flake.lock` - Pinned versions of all dependencies (auto-generated)
- `configuration.nix` - Main system configuration (unchanged)

## Troubleshooting

### "Path not tracked by Git"

Flakes require files to be tracked by git:

```bash
cd /etc/nixos
git add <new-file>
# Then rebuild
```

### Slow First Build

First build downloads all dependencies. Subsequent builds use cache.

### Revert to Channels

If needed, you can temporarily use channels again:

```bash
# Uncomment nixos-hardware in configuration.nix
# Then run without --flake flag:
sudo nixos-rebuild switch
```

## Useful Commands

```bash
# Show flake info
nix flake show /etc/nixos

# Show flake metadata (inputs, versions)
nix flake metadata /etc/nixos

# Check flake for errors
nix flake check /etc/nixos

# Enter dev shell (has nix tools)
nix develop /etc/nixos
```

## Flake Inputs

This flake uses:

| Input | Description | URL |
|-------|-------------|-----|
| `nixpkgs` | Stable packages (25.11) | `github:nixos/nixpkgs/nixos-25.11` |
| `nixpkgs-unstable` | Latest packages | `github:nixos/nixpkgs/nixos-unstable` |
| `nixos-hardware` | Hardware quirks for Dell XPS 13 | `github:nixos/nixos-hardware` |
