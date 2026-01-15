---
name: nixos-core
description: Core NixOS configuration knowledge. Triggers on: any .nix file, "module", "service", "package", "option", "config", flake work, nixos-rebuild, configuration changes
---

# NixOS Core Skill

## Validation Flow
1. Edit file -> `nix-instantiate --parse`
2. Before commit -> `nix flake check`
3. Before switch -> `nixos-rebuild build`
4. Apply -> `nixos-rebuild switch`

## Module Structure
Always use:
```nix
{ config, lib, pkgs, ... }:
let cfg = config.modules.X; in
{
  options.modules.X = { enable = lib.mkEnableOption "X"; };
  config = lib.mkIf cfg.enable { ... };
}
```

## Common lib Functions
- `lib.mkIf` - Conditional config
- `lib.mkEnableOption` - Boolean enable option
- `lib.mkOption` - Custom option
- `lib.mkDefault` - Default with low priority
- `lib.mkForce` - Override with high priority
- `lib.mkMerge` - Merge multiple configs
- `lib.optionals` - Conditional list items
- `lib.optionalString` - Conditional string
- `lib.recursiveUpdate` - Deep merge attribute sets

## Build Commands
```bash
# Syntax check single file
nix-instantiate --parse <file.nix>

# Check all files
find /etc/nixos -name "*.nix" -not -path "*/.git/*" -exec nix-instantiate --parse {} \;

# Flake check
nix flake check

# Dry build
sudo nixos-rebuild dry-build --flake /etc/nixos#hanibal

# Build without activating
sudo nixos-rebuild build --flake /etc/nixos#hanibal

# Apply changes
sudo nixos-rebuild switch --flake /etc/nixos#hanibal

# Test without making permanent
sudo nixos-rebuild test --flake /etc/nixos#hanibal
```

## Anti-Patterns
- Hardcoded paths (use `pkgs.X` or options)
- `with pkgs;` at module level (pollutes scope)
- Missing `lib.mkIf` for conditional config
- Circular imports
- Modifying hardware-configuration.nix
- Using `rec { }` instead of `let ... in`
- Top-level `with` statements
- Using `<nixpkgs>` lookup paths

## Essential Arguments
Always include in module arguments:
```nix
{ config, lib, pkgs, ... }:  # ... is critical!
```

## Priority System
| Function | Priority | When to Use |
|----------|----------|-------------|
| `mkDefault` | 1000 | Providing fallback values |
| (direct) | 100 | Normal configuration |
| `mkForce` | 50 | Must override conflicting modules |
