# NixOS Configuration Modularization

## Trigger
Organizing large NixOS configurations, multi-host setups, or refactoring monolithic configs.

## Overview

NixOS configurations are modular by design. The `imports` mechanism allows splitting large configurations into focused, reusable pieces. This guide covers patterns for organizing configurations from simple single-host setups to complex multi-machine deployments.

---

## Basic Concepts

### How Imports Work

```nix
# configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/networking.nix
    ./modules/users.nix
  ];

  # Additional configuration...
}
```

**Key Points:**
- `imports` accepts a list of paths to `.nix` files
- All imported configurations are **merged** together
- If path is a directory, Nix loads `default.nix` from it
- Import order doesn't matter (except for priority conflicts)

### Directory as Module

```nix
# These are equivalent:
imports = [ ./modules/networking.nix ];
imports = [ ./modules/networking ];  # Loads ./modules/networking/default.nix
```

---

## Recommended Directory Structures

### Simple Single-Host

```
/etc/nixos/
├── configuration.nix      # Main entry point
├── hardware-configuration.nix  # Auto-generated
├── hardware.nix           # Custom hardware tweaks
├── packages.nix           # System packages
├── services.nix           # System services
└── users.nix              # User accounts
```

### Medium Complexity (Single Host with Categories)

```
/etc/nixos/
├── flake.nix
├── flake.lock
├── configuration.nix
├── hardware-configuration.nix
│
├── modules/
│   ├── core/
│   │   ├── default.nix    # Imports all core modules
│   │   ├── boot.nix
│   │   ├── networking.nix
│   │   └── security.nix
│   │
│   ├── desktop/
│   │   ├── default.nix
│   │   ├── gnome.nix
│   │   ├── i3.nix
│   │   └── fonts.nix
│   │
│   ├── services/
│   │   ├── default.nix
│   │   ├── docker.nix
│   │   ├── ssh.nix
│   │   └── printing.nix
│   │
│   └── hardware/
│       ├── default.nix
│       ├── audio.nix
│       ├── bluetooth.nix
│       └── power.nix
│
├── home/                  # Home Manager configs
│   ├── default.nix
│   ├── shell.nix
│   └── programs/
│
└── overlays/
    └── default.nix
```

### Multi-Host with Flakes

```
nixos-config/
├── flake.nix              # Entry point, defines all hosts
├── flake.lock
│
├── hosts/
│   ├── common/            # Shared by all hosts
│   │   ├── default.nix
│   │   ├── nix.nix        # Nix settings
│   │   ├── security.nix
│   │   └── users.nix
│   │
│   ├── laptop/
│   │   ├── default.nix    # Host-specific config
│   │   ├── hardware-configuration.nix
│   │   └── hardware.nix
│   │
│   ├── desktop/
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix
│   │   └── nvidia.nix
│   │
│   └── server/
│       ├── default.nix
│       ├── hardware-configuration.nix
│       └── services.nix
│
├── modules/               # Reusable NixOS modules
│   ├── desktop/
│   │   ├── gnome.nix
│   │   ├── hyprland.nix
│   │   └── gaming.nix
│   │
│   ├── services/
│   │   ├── docker.nix
│   │   ├── nginx.nix
│   │   └── postgresql.nix
│   │
│   └── hardware/
│       ├── intel.nix
│       ├── amd.nix
│       └── nvidia.nix
│
├── home/                  # Home Manager modules
│   ├── common/
│   │   ├── default.nix
│   │   ├── shell.nix
│   │   └── git.nix
│   │
│   ├── desktop/
│   │   └── ...
│   │
│   └── users/
│       ├── alice.nix
│       └── bob.nix
│
├── overlays/
│   ├── default.nix
│   └── custom-packages.nix
│
├── packages/              # Custom packages
│   └── my-tool/
│       └── default.nix
│
└── secrets/               # Encrypted secrets (sops/agenix)
    ├── secrets.yaml
    └── .sops.yaml
```

---

## Flake Configuration Patterns

### Basic Multi-Host Flake

```nix
# flake.nix
{
  description = "My NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      # Helper function to create NixOS configurations
      mkHost = { hostname, system ? "x86_64-linux", extraModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs;
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };

          modules = [
            # Common modules for all hosts
            ./hosts/common

            # Host-specific configuration
            ./hosts/${hostname}

            # Home Manager as NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ] ++ extraModules;
        };
    in {
      nixosConfigurations = {
        laptop = mkHost {
          hostname = "laptop";
          extraModules = [
            ./modules/desktop/gnome.nix
            ./modules/hardware/intel.nix
          ];
        };

        desktop = mkHost {
          hostname = "desktop";
          extraModules = [
            ./modules/desktop/hyprland.nix
            ./modules/hardware/nvidia.nix
            ./modules/services/gaming.nix
          ];
        };

        server = mkHost {
          hostname = "server";
          extraModules = [
            ./modules/services/docker.nix
            ./modules/services/nginx.nix
          ];
        };
      };
    };
}
```

### Host Common Configuration

```nix
# hosts/common/default.nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./nix.nix
    ./security.nix
    ./users.nix
    ./networking.nix
  ];

  # Settings common to all hosts
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Common packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];
}
```

### Host-Specific Configuration

```nix
# hosts/laptop/default.nix
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
  ];

  networking.hostName = "laptop";

  # Laptop-specific settings
  services.tlp.enable = true;
  services.thermald.enable = true;

  # Use unstable packages for some apps
  environment.systemPackages = [
    pkgs-unstable.firefox
    pkgs-unstable.vscode
  ];
}
```

---

## Module Patterns

### Toggle Module Pattern

Create modules that can be enabled/disabled:

```nix
# modules/services/docker.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.my.services.docker;
in {
  options.my.services.docker = {
    enable = lib.mkEnableOption "Docker container runtime";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Users to add to docker group";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = [ "docker" ];
    });
  };
}
```

Usage:
```nix
# In host configuration
{
  imports = [ ../../modules/services/docker.nix ];

  my.services.docker = {
    enable = true;
    users = [ "alice" "bob" ];
  };
}
```

### Profile Pattern

Create profiles for different use cases:

```nix
# modules/profiles/gaming.nix
{ config, lib, pkgs, ... }:

{
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    lutris
    mangohud
    gamemode
  ];

  # Performance tweaks
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };
}
```

### Feature Flag Pattern

```nix
# modules/desktop/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.my.desktop;
in {
  options.my.desktop = {
    environment = lib.mkOption {
      type = lib.types.enum [ "gnome" "kde" "hyprland" "i3" "none" ];
      default = "none";
      description = "Desktop environment to use";
    };

    gaming = lib.mkEnableOption "gaming support";
    development = lib.mkEnableOption "development tools";
  };

  config = lib.mkMerge [
    # GNOME
    (lib.mkIf (cfg.environment == "gnome") {
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    })

    # KDE
    (lib.mkIf (cfg.environment == "kde") {
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
    })

    # Hyprland
    (lib.mkIf (cfg.environment == "hyprland") {
      programs.hyprland.enable = true;
    })

    # Gaming (can be combined with any DE)
    (lib.mkIf cfg.gaming {
      imports = [ ../profiles/gaming.nix ];
    })
  ];
}
```

---

## Import Patterns

### Conditional Imports

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ] ++ lib.optionals config.services.xserver.enable [
    ./desktop.nix
  ] ++ lib.optionals (builtins.pathExists ./local.nix) [
    ./local.nix  # Optional local overrides
  ];
}
```

### Dynamic Module Loading

```nix
# Load all .nix files from a directory
{ config, lib, pkgs, ... }:

let
  modulesDir = ./modules;
  moduleFiles = builtins.filter
    (name: lib.hasSuffix ".nix" name && name != "default.nix")
    (builtins.attrNames (builtins.readDir modulesDir));
in {
  imports = map (name: modulesDir + "/${name}") moduleFiles;
}
```

### Import with Arguments

```nix
# When you need to pass extra arguments
{ config, lib, pkgs, ... }:

{
  imports = [
    (import ./module.nix { inherit config lib pkgs; customArg = "value"; })
  ];
}
```

---

## Priority and Merging

### Using mkDefault for Overridable Defaults

```nix
# modules/base.nix - Provides defaults
{ lib, ... }:

{
  services.openssh.enable = lib.mkDefault true;
  networking.firewall.enable = lib.mkDefault true;
}

# hosts/insecure-test/default.nix - Overrides defaults
{ lib, ... }:

{
  imports = [ ../../modules/base.nix ];

  # Easy to override mkDefault
  services.openssh.enable = false;
  networking.firewall.enable = false;
}
```

### Using mkForce for Non-Negotiable Settings

```nix
# modules/security.nix - Security requirements
{ lib, ... }:

{
  # Can't be overridden by other modules
  security.sudo.wheelNeedsPassword = lib.mkForce true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "no";
}
```

### List Ordering

```nix
{ lib, pkgs, ... }:

{
  # Normal - appended to list
  environment.systemPackages = [ pkgs.vim ];

  # Prepend to list
  environment.systemPackages = lib.mkBefore [ pkgs.important-tool ];

  # Append explicitly
  environment.systemPackages = lib.mkAfter [ pkgs.optional-tool ];
}
```

---

## Best Practices

### DO

1. **Split by concern**, not by file type
   ```
   GOOD: modules/services/nginx.nix  (nginx config + packages + firewall)
   BAD:  modules/packages.nix        (all packages in one file)
   ```

2. **Use `default.nix` for directories**
   ```nix
   # modules/desktop/default.nix
   { ... }: {
     imports = [
       ./gnome.nix
       ./fonts.nix
       ./themes.nix
     ];
   }
   ```

3. **Keep host-specific configs minimal**
   - Hardware config + hostname + host-specific overrides only
   - Everything else in reusable modules

4. **Use specialArgs for flake inputs**
   ```nix
   specialArgs = { inherit inputs; };
   ```

5. **Create a common base for all hosts**
   - Reduces duplication
   - Ensures consistency

### DON'T

1. **Don't put everything in configuration.nix**
   - Hard to maintain
   - Can't reuse across hosts

2. **Don't over-modularize**
   - Don't create a file for every single option
   - Group related settings together

3. **Don't use relative imports across module boundaries**
   ```nix
   # BAD - fragile
   imports = [ ../../../other-module.nix ];

   # GOOD - explicit
   imports = [ /etc/nixos/modules/other-module.nix ];
   ```

4. **Don't forget to export modules in flake.nix**
   - If you want modules usable by others

---

## Migration Guide

### From Monolithic to Modular

1. **Start with hardware-configuration.nix** - Already separate

2. **Extract users.nix**
   ```nix
   # Move all users.users.* to users.nix
   ```

3. **Extract services by category**
   ```nix
   # services/ssh.nix, services/docker.nix, etc.
   ```

4. **Create a common module**
   ```nix
   # hosts/common/default.nix with shared settings
   ```

5. **Add imports to main configuration**
   ```nix
   imports = [
     ./hardware-configuration.nix
     ./users.nix
     ./services/ssh.nix
     # ...
   ];
   ```

---

## Notable Examples

| Repository | Pattern | Highlights |
|------------|---------|------------|
| [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) | Multi-host + profiles | NixOS + macOS, extensive modules |
| [Misterio77/nix-config](https://github.com/Misterio77/nix-config) | Impermanence + secrets | sops-nix, YubiKey, BTRFS |
| [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) | VM-based dev | macOS host + NixOS VM |
| [nix-community/srvos](https://github.com/nix-community/srvos) | Server modules | Production-ready server configs |

## Confidence
0.95 - Patterns from community best practices and notable configurations.

## Sources
- [NixOS & Flakes Book - Modularize](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)
- [NixOS Wiki - Modules](https://wiki.nixos.org/wiki/NixOS_modules)
- [nix.dev - Module System](https://nix.dev/tutorials/module-system/deep-dive.html)
