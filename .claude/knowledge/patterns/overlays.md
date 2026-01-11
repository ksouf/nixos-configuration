# NixOS Overlays

## Trigger
Modifying packages, adding custom packages, or patching existing packages.

## Overview

Overlays are functions that modify the Nixpkgs package set. They let you:
- Override package versions or build options
- Add custom packages
- Apply patches
- Replace packages entirely

---

## Basic Syntax

```nix
# Overlay function signature
final: prev: {
  # Your modifications
}
```

| Argument | Description |
|----------|-------------|
| `final` | The final package set (after all overlays applied) |
| `prev` | The package set before this overlay |

**Rule:** Use `prev` when modifying an existing package. Use `final` when depending on other packages.

---

## Applying Overlays

### Method 1: In NixOS Configuration

```nix
# configuration.nix or flake module
{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      mypackage = prev.mypackage.override { ... };
    })

    # Import from file
    (import ./overlays/custom.nix)
  ];
}
```

### Method 2: In Flake

```nix
# flake.nix
{
  outputs = { nixpkgs, ... }: {
    overlays.default = final: prev: {
      mypackage = prev.mypackage.override { ... };
    };

    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [ self.overlays.default ];
        }
        ./configuration.nix
      ];
    };
  };
}
```

### Method 3: Separate Overlays Directory

```
overlays/
├── default.nix         # Combines all overlays
├── python-packages.nix
├── patches.nix
└── custom-packages.nix
```

```nix
# overlays/default.nix
final: prev:
let
  python = import ./python-packages.nix final prev;
  patches = import ./patches.nix final prev;
  custom = import ./custom-packages.nix final prev;
in
python // patches // custom
```

---

## Common Patterns

### 1. Override Package Inputs

```nix
final: prev: {
  # Change a dependency
  myapp = prev.myapp.override {
    python = final.python311;  # Use Python 3.11
  };

  # Multiple overrides
  ffmpeg = prev.ffmpeg.override {
    withVaapi = true;
    withVdpau = true;
    withXcb = true;
  };
}
```

### 2. Override Derivation Attributes

```nix
final: prev: {
  # Modify build attributes
  htop = prev.htop.overrideAttrs (old: {
    # Add patch
    patches = (old.patches or []) ++ [
      ./htop-custom.patch
    ];

    # Change version
    version = "3.3.0";

    # Modify source
    src = prev.fetchFromGitHub {
      owner = "htop-dev";
      repo = "htop";
      rev = "3.3.0";
      sha256 = "sha256-...";
    };

    # Add build flags
    configureFlags = (old.configureFlags or []) ++ [
      "--enable-feature"
    ];
  });
}
```

### 3. Add Custom Packages

```nix
final: prev: {
  # Simple package
  mytool = prev.stdenv.mkDerivation {
    pname = "mytool";
    version = "1.0.0";
    src = ./mytool-src;
    buildInputs = [ prev.openssl ];
    installPhase = ''
      mkdir -p $out/bin
      cp mytool $out/bin/
    '';
  };

  # From fetchFromGitHub
  myapp = prev.callPackage ./pkgs/myapp { };
}
```

### 4. Pin Package Version

```nix
final: prev: {
  # Use older version from another nixpkgs
  nodejs = (import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-23.11.tar.gz";
    sha256 = "...";
  }) { system = prev.system; }).nodejs;
}
```

### 5. Add Packages from Unstable

```nix
# With flake inputs
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      # Specific packages from unstable
      firefox = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.firefox;
      vscode = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.vscode;
    })
  ];
}
```

### 6. Patch Package

```nix
final: prev: {
  nginx = prev.nginx.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      # Local patch
      ./nginx-custom.patch

      # Fetched patch
      (prev.fetchpatch {
        url = "https://example.com/fix.patch";
        sha256 = "sha256-...";
      })
    ];
  });
}
```

### 7. Change Build Options

```nix
final: prev: {
  # Build with different flags
  ffmpeg = prev.ffmpeg.override {
    withFdkAac = true;
    withUnfree = true;
  };

  # Disable tests for faster builds
  mypackage = prev.mypackage.overrideAttrs (old: {
    doCheck = false;
  });
}
```

---

## Language-Specific Overlays

### Python

```nix
final: prev: {
  python3 = prev.python3.override {
    packageOverrides = python-final: python-prev: {
      # Override Python package
      requests = python-prev.requests.overridePythonAttrs (old: {
        version = "2.28.0";
        src = prev.fetchPypi {
          pname = "requests";
          version = "2.28.0";
          sha256 = "sha256-...";
        };
      });

      # Add custom Python package
      mylib = python-prev.buildPythonPackage {
        pname = "mylib";
        version = "1.0.0";
        src = ./mylib;
      };
    };
  };
}
```

### Rust

```nix
final: prev: {
  rustPlatform = prev.rustPlatform // {
    buildRustPackage = args: prev.rustPlatform.buildRustPackage (args // {
      # Global Rust settings
      RUSTFLAGS = "-C target-cpu=native";
    });
  };
}
```

### Node.js

```nix
final: prev: {
  nodePackages = prev.nodePackages // {
    # Override npm package
    typescript = prev.nodePackages.typescript.override {
      version = "5.0.0";
    };
  };
}
```

---

## Scoped Overlays

For package sets like GNOME, Xfce, etc.

```nix
final: prev: {
  gnome = prev.gnome.overrideScope (gnome-final: gnome-prev: {
    # Override GNOME package
    nautilus = gnome-prev.nautilus.overrideAttrs (old: {
      patches = (old.patches or []) ++ [ ./nautilus.patch ];
    });
  });
}
```

---

## Flake Overlay Best Practices

### Export Overlay from Flake

```nix
# flake.nix
{
  outputs = { self, nixpkgs }: {
    # Export overlay for others to use
    overlays = {
      default = final: prev: {
        mypackage = final.callPackage ./pkgs/mypackage { };
      };

      # Named overlays
      customTools = final: prev: { ... };
      patches = final: prev: { ... };
    };

    # Use in your own config
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [{
        nixpkgs.overlays = [
          self.overlays.default
          self.overlays.patches
        ];
      }];
    };
  };
}
```

### Consume Overlay from Another Flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "...";
    cool-tools.url = "github:someone/cool-tools";
  };

  outputs = { nixpkgs, cool-tools, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [{
        nixpkgs.overlays = [
          cool-tools.overlays.default
        ];
      }];
    };
  };
}
```

---

## Anti-Patterns

### DON'T: Use `final` When Modifying Same Package

```nix
# WRONG - Infinite recursion!
final: prev: {
  mypackage = final.mypackage.override { ... };
}

# CORRECT
final: prev: {
  mypackage = prev.mypackage.override { ... };
}
```

### DON'T: Overlay Everything

```nix
# BAD - Invalidates all caches
final: prev: {
  stdenv = prev.stdenv.override { ... };  # Everything rebuilds!
}

# BETTER - Only overlay what you need
final: prev: {
  myspecificpackage = prev.myspecificpackage.override { ... };
}
```

### DON'T: Use Impure Paths

```nix
# BAD - Depends on local filesystem
final: prev: {
  mypackage = prev.callPackage ~/.config/nixpkgs/mypackage { };
}

# GOOD - Use paths relative to flake
final: prev: {
  mypackage = prev.callPackage ./pkgs/mypackage { };
}
```

### DON'T: Forget `or []` for Lists

```nix
# WRONG - Fails if patches doesn't exist
patches = old.patches ++ [ ./my.patch ];

# CORRECT
patches = (old.patches or []) ++ [ ./my.patch ];
```

---

## Debugging

### Check if Overlay Applied

```bash
# In nix repl
:l <nixpkgs>
:l <nixpkgs/nixos>

# Check package
pkgs.mypackage
pkgs.mypackage.version

# Trace evaluation
nix eval --impure --expr 'with import <nixpkgs> {}; mypackage.version'
```

### Find Overlay Issues

```bash
# Build with verbose
nix build .#mypackage -L

# Show derivation
nix show-derivation .#mypackage
```

---

## Examples

### Custom Firefox with Extensions

```nix
final: prev: {
  firefox = prev.firefox.override {
    extraPolicies = {
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
    };
  };
}
```

### Neovim with Custom Config

```nix
final: prev: {
  neovim = prev.neovim.override {
    configure = {
      customRC = ''
        set number
        set relativenumber
      '';
      packages.myPlugins = with prev.vimPlugins; {
        start = [ vim-nix telescope-nvim ];
      };
    };
  };
}
```

### Steam with Extra Libraries

```nix
final: prev: {
  steam = prev.steam.override {
    extraPkgs = pkgs: with pkgs; [
      gamemode
      mangohud
    ];
  };
}
```

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Override input | `pkg.override { dep = ...; }` |
| Modify derivation | `pkg.overrideAttrs (old: { ... })` |
| Add package | `myPkg = prev.callPackage ./pkg { }` |
| Add patch | `patches = (old.patches or []) ++ [...]` |
| Use `final` | When referencing other packages |
| Use `prev` | When modifying existing package |
| Scoped override | `gnome.overrideScope (f: p: {...})` |

## Confidence
1.0 - Core Nix functionality from official documentation.

## Sources
- [NixOS Wiki - Overlays](https://wiki.nixos.org/wiki/Overlays)
- [Nixpkgs Manual - Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [NixOS & Flakes Book - Overlays](https://nixos-and-flakes.thiscute.world/nixpkgs/overlays)
