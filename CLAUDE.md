# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS configuration repository for a Dell XPS 13-9370 developer workstation. The system uses declarative configuration with modular organization and Nix Flakes.

## Build Commands

```bash
# Apply configuration changes (with flakes)
sudo nixos-rebuild switch --flake /etc/nixos#hanibal

# Test changes without making permanent
sudo nixos-rebuild test --flake /etc/nixos#hanibal

# Build without activating
sudo nixos-rebuild build --flake /etc/nixos#hanibal

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Update flake inputs
cd /etc/nixos && nix flake update
```

## Architecture

### Entry Point
- `flake.nix` - Flake definition with inputs (nixpkgs, nixos-hardware)
- `configuration.nix` - Main configuration that imports all modules

### Module Organization

| Directory | Purpose |
|-----------|---------|
| `modules/` | Core system modules (security hardening) |
| `desktop/` | Desktop environments (GNOME active, i3/Hyprland alternatives) |
| `devices/` | Hardware configs (audio, bluetooth, network, keyboards, LUKS encryption) |
| `shell/` | Shell environment (Zsh with Oh-My-Zsh, Tilix terminal) |
| `home-manager-target/` | User applications organized by category |
| `.claude/` | Self-improving automation system |

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

The configuration uses flakes with two nixpkgs inputs:
- **nixpkgs** (stable 25.11) - Base system packages
- **nixpkgs-unstable** - Newer versions for frequently-updated apps

To use unstable packages in a module (flake-compatible):
```nix
{ config, pkgs, pkgs-unstable ? null, ... }:
let
  # Support both flakes (pkgs-unstable) and channels (<nixos-unstable>)
  unstable = if pkgs-unstable != null
    then pkgs-unstable
    else import <nixos-unstable> { config = { allowUnfree = true; }; };
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
3. Run `sudo nixos-rebuild switch --flake /etc/nixos#hanibal`

### New Module Pattern
```nix
{ config, pkgs, lib, ... }:

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
- **Keyboard:** French layout

---

## Self-Improving Automation System

This repository includes a self-improving system that learns from patterns and evolves its rules.

### Directory Structure

```
.claude/
├── agents/           # Agent definitions (auditor, fixer, evolver)
├── rules/            # Detection rules
│   └── learned/      # Auto-generated rules from patterns
├── hooks/            # Hook scripts
├── memory/           # Persistent memory (JSONL files)
│   ├── issues.jsonl      # Detected issues
│   ├── fixes.jsonl       # Applied fixes
│   ├── patterns.jsonl    # Learned patterns
│   ├── improvements.jsonl # System improvements
│   ├── metrics.jsonl     # Tracking metrics
│   └── events.jsonl      # Hook events
├── evolution/        # Pattern detection and rule generation
├── triggers/         # Event triggers
├── templates/        # Templates for generated content
├── skills/           # Custom skills
└── commands/         # Custom commands
```

### Agents

#### Auditor Agent
Scans configuration for issues, security gaps, and deprecated options.
```
Invoke: "audit the NixOS configuration"
```

#### Fixer Agent
Applies fixes for detected issues, validates changes.
```
Invoke: "fix detected issues in NixOS configuration"
```

#### Evolver Agent
Learns from patterns, generates rules, improves the system.
```
Invoke: "evolve the self-improving system"
```

### Rules

Rules are stored in `.claude/rules/` and define:
- **Trigger**: What activates the rule
- **Detection**: How to find issues (regex, patterns)
- **Fix**: How to resolve the issue
- **Confidence**: Score based on success rate

Built-in rules:
- `nixos-deprecations.md` - Deprecated NixOS options
- `nixos-security.md` - Security best practices
- `nixos-audio.md` - Audio configuration (learned from fixing this system)

### Memory System

The system maintains persistent memory in JSONL format:

- **issues.jsonl**: All detected issues with severity and resolution status
- **fixes.jsonl**: Applied fixes with before/after content
- **patterns.jsonl**: Recurring patterns identified across sessions
- **metrics.jsonl**: System evolution metrics

### Hooks

Hooks trigger on Claude Code events:
- **post-edit.sh**: Runs after Edit/Write tools, logs changes
- **pre-commit.sh**: Validates Nix syntax before git commits
- **on-tool-use.sh**: Tracks tool usage patterns

### Evolution Process

1. **Detect**: Issues found during audits
2. **Record**: Store in memory with context
3. **Analyze**: Group similar issues into patterns
4. **Generate**: Create rules for recurring patterns (4+ occurrences)
5. **Validate**: Track fix success rate
6. **Evolve**: Improve confidence scores, archive failing rules

### Best Practices for This Codebase

1. **Always include `lib`** in module arguments when using `mkForce` or `mkDefault`
2. **Never set audio kernel params** like `probe_mask` or `model=generic`
3. **Use flake-compatible pattern** for unstable packages (`pkgs-unstable ? null`)
4. **Validate changes** with `nix-instantiate --parse` before committing
5. **Check deprecations** against `.claude/rules/nixos-deprecations.md`
