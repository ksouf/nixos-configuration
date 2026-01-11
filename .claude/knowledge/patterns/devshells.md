# Nix Development Shells

## Trigger
Creating reproducible development environments, project-specific tooling, or team development setups.

## Overview

Nix development shells provide:
- Reproducible environments across machines
- Project-specific dependencies
- Isolated toolchains
- Automatic environment activation

---

## Basic devShell

### Flake-based (Recommended)

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_20
          python311
          git
        ];

        shellHook = ''
          echo "Development environment loaded!"
        '';
      };
    };
}
```

```bash
# Enter shell
nix develop

# Run command in shell
nix develop -c npm install
```

### Legacy shell.nix

```nix
# shell.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs_20
    python311
  ];
}
```

```bash
nix-shell
```

---

## Multi-System Support

### Using flake-utils

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs python3 ];
        };
      }
    );
}
```

### Using flake-parts

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs python3 ];
        };
      };
    };
}
```

---

## Language-Specific Shells

### Node.js / JavaScript

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      nodejs_20
      nodePackages.npm
      nodePackages.pnpm
      nodePackages.typescript
      nodePackages.typescript-language-server
    ];

    shellHook = ''
      export PATH="$PWD/node_modules/.bin:$PATH"
    '';
  };
}
```

### Python

```nix
{ pkgs, ... }:

let
  python = pkgs.python311;
  pythonPackages = python.pkgs;
in {
  devShells.default = pkgs.mkShell {
    packages = [
      python
      pythonPackages.pip
      pythonPackages.virtualenv
      pythonPackages.black
      pythonPackages.pytest
      pythonPackages.mypy

      # For packages with C extensions
      pkgs.gcc
      pkgs.pkg-config
    ];

    shellHook = ''
      # Create venv if it doesn't exist
      if [ ! -d .venv ]; then
        python -m venv .venv
      fi
      source .venv/bin/activate

      # Install dependencies
      pip install -q -r requirements.txt 2>/dev/null || true
    '';

    # For packages that need these
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc
    ];
  };
}
```

### Rust

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer

      # For building native dependencies
      pkg-config
      openssl
    ];

    # Rust-specific environment
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    RUST_BACKTRACE = 1;

    shellHook = ''
      # Use sccache for faster builds
      export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
    '';
  };
}
```

### Go

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      go
      gopls
      gotools
      go-tools
      golangci-lint
      delve  # Debugger
    ];

    shellHook = ''
      export GOPATH="$PWD/.go"
      export PATH="$GOPATH/bin:$PATH"
    '';
  };
}
```

### Java / JVM

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      jdk17
      maven
      gradle
    ];

    JAVA_HOME = pkgs.jdk17;

    shellHook = ''
      export PATH="$JAVA_HOME/bin:$PATH"
    '';
  };
}
```

### C/C++

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      gcc
      cmake
      gnumake
      gdb
      valgrind
      clang-tools  # clangd, clang-format
    ];

    # For finding headers
    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
      zlib
    ];
  };
}
```

---

## Advanced Patterns

### Multiple Shells

```nix
{
  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux = {
        # Default shell
        default = pkgs.mkShell {
          packages = with pkgs; [ nodejs python3 ];
        };

        # Backend development
        backend = pkgs.mkShell {
          packages = with pkgs; [ python311 postgresql redis ];
        };

        # Frontend development
        frontend = pkgs.mkShell {
          packages = with pkgs; [ nodejs_20 nodePackages.pnpm ];
        };

        # Full stack
        fullstack = pkgs.mkShell {
          inputsFrom = [
            self.devShells.x86_64-linux.backend
            self.devShells.x86_64-linux.frontend
          ];
        };
      };
    };
}
```

```bash
nix develop .#backend
nix develop .#frontend
nix develop .#fullstack
```

### With Services

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      postgresql
      redis
    ];

    shellHook = ''
      # Create data directories
      mkdir -p .data/{postgres,redis}

      # Start PostgreSQL
      if [ ! -d .data/postgres/data ]; then
        initdb -D .data/postgres/data
      fi
      pg_ctl -D .data/postgres/data -l .data/postgres/log -o "-k $PWD/.data/postgres" start

      # Start Redis
      redis-server --daemonize yes --dir .data/redis

      # Cleanup on exit
      trap "pg_ctl -D .data/postgres/data stop; redis-cli shutdown" EXIT

      export DATABASE_URL="postgresql://localhost/myapp?host=$PWD/.data/postgres"
      export REDIS_URL="redis://localhost:6379"
    '';
  };
}
```

### Environment Variables

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [ nodejs ];

    # Set environment variables
    MY_VAR = "value";
    API_URL = "http://localhost:3000";

    # Or in shellHook for dynamic values
    shellHook = ''
      export PROJECT_ROOT="$PWD"
      export PATH="$PROJECT_ROOT/scripts:$PATH"

      # Load .env file if exists
      if [ -f .env ]; then
        set -a
        source .env
        set +a
      fi
    '';
  };
}
```

### Native Dependencies

```nix
{ pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      python3
    ];

    # Tools needed at build time
    nativeBuildInputs = with pkgs; [
      pkg-config
      cmake
    ];

    # Libraries to link against
    buildInputs = with pkgs; [
      openssl
      zlib
      libpng
      libjpeg
    ];

    # Help compilers find libraries
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.openssl
      pkgs.zlib
    ];

    # For node-gyp
    shellHook = ''
      export npm_config_build_from_source=true
    '';
  };
}
```

---

## Direnv Integration

Auto-load environment when entering directory.

### Setup

```nix
# In home-manager or NixOS
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

### Usage

```bash
# In project directory
echo "use flake" > .envrc
direnv allow
```

```bash
# .envrc options
use flake                    # Use default devShell
use flake .#backend          # Use specific shell
use flake ./path/to/flake    # Use flake from path
```

### With Extra Environment

```bash
# .envrc
use flake

# Additional setup
export MY_VAR="value"
PATH_add scripts

# Load secrets
dotenv_if_exists .env.local
```

---

## devenv (Higher-Level)

Simpler syntax with built-in features.

### Installation

```bash
nix profile install nixpkgs#devenv
```

### Configuration

```nix
# devenv.nix
{ pkgs, ... }:

{
  # Packages
  packages = with pkgs; [
    git
    curl
  ];

  # Languages
  languages.python = {
    enable = true;
    version = "3.11";
    venv.enable = true;
    venv.requirements = ./requirements.txt;
  };

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_20;
  };

  # Services
  services.postgres = {
    enable = true;
    initialScript = "CREATE DATABASE myapp;";
  };

  services.redis.enable = true;

  # Environment
  env.DATABASE_URL = "postgresql://localhost/myapp";

  # Scripts
  scripts.dev.exec = "npm run dev";
  scripts.test.exec = "pytest";

  # Pre-commit hooks
  pre-commit.hooks = {
    nixfmt.enable = true;
    black.enable = true;
    eslint.enable = true;
  };

  # Process manager
  processes.web.exec = "npm start";
  processes.worker.exec = "python worker.py";
}
```

### Usage

```bash
devenv shell     # Enter shell
devenv up        # Start processes
devenv test      # Run tests
devenv gc        # Garbage collect
```

---

## Pure vs Impure Shells

### Pure Shell

Isolated from system environment:

```bash
nix develop --ignore-environment

# Or in flake
devShells.default = pkgs.mkShell {
  # Only these are available
  packages = [ pkgs.nodejs ];
};
```

### Impure Shell (Default)

Inherits system environment:

```bash
nix develop  # System tools still available
```

### Best Practice

```nix
{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      # Include common tools explicitly
      git
      curl
      which
    ];

    # Pure mode in CI
    # nix develop --ignore-environment -c npm test
  };
}
```

---

## Caching devShells

### Cachix

```bash
# Push devShell to cache
nix build .#devShells.x86_64-linux.default
cachix push mycache ./result

# Or with shell
nix develop --profile dev-profile
nix store copy --to "file:///tmp/cache" ./dev-profile
```

### In CI

```yaml
# GitHub Actions
- uses: cachix/install-nix-action@v27
- uses: cachix/cachix-action@v14
  with:
    name: mycache
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
- run: nix develop -c npm test
```

---

## Common Patterns

### Pinned Dependencies

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Pin specific commit for stability
    nixpkgs-python.url = "github:NixOS/nixpkgs/abc123";
  };

  outputs = { nixpkgs, nixpkgs-python, ... }: {
    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      pythonPkgs = nixpkgs-python.legacyPackages.x86_64-linux;
    in pkgs.mkShell {
      packages = [
        pythonPkgs.python311  # Specific Python version
        pkgs.nodejs           # Latest stable Node
      ];
    };
  };
}
```

### Cross-Platform

```nix
{
  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              # Platform-specific
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
            ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.inotify-tools
            ];
          };
        }
      );
    };
}
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `nix develop` | Enter default devShell |
| `nix develop .#name` | Enter named devShell |
| `nix develop -c cmd` | Run command in shell |
| `nix develop --ignore-environment` | Pure shell |
| `direnv allow` | Enable auto-activation |
| `devenv shell` | Enter devenv shell |
| `devenv up` | Start devenv services |

## Confidence
0.95 - Patterns from Nix documentation and community usage.

## Sources
- [nix.dev - Dev Shells](https://nix.dev/tutorials/first-steps/declarative-shell.html)
- [devenv](https://devenv.sh/)
- [direnv](https://direnv.net/)
- [NixOS Wiki - Development Environments](https://nixos.wiki/wiki/Development_environment_with_nix-shell)
