# NixOS Remote Deployment

## Trigger
Deploying NixOS configurations to remote machines, managing multiple hosts, or setting up CI/CD.

## Overview

NixOS supports several deployment methods:

| Method | Best For | Complexity |
|--------|----------|------------|
| `nixos-rebuild --target-host` | Simple remote deploy | Low |
| **colmena** | Multi-host, parallel | Medium |
| **deploy-rs** | Rollback safety | Medium |
| **nixos-anywhere** | Fresh installs | Medium |

---

## Prerequisites

### SSH Key Authentication

```nix
# On target machine
users.users.deploy = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... deploy@admin"
  ];
};

# Passwordless sudo for deploy user (if not using root)
security.sudo.extraRules = [{
  users = [ "deploy" ];
  commands = [{
    command = "ALL";
    options = [ "NOPASSWD" ];
  }];
}];
```

### Known Hosts

```bash
# Add target to known hosts
ssh-keyscan -H target.example.com >> ~/.ssh/known_hosts

# Or in NixOS config
programs.ssh.knownHosts = {
  "target.example.com".publicKey = "ssh-ed25519 AAAA...";
};
```

---

## Method 1: nixos-rebuild (Built-in)

Simplest method, uses built-in `nixos-rebuild`.

### Basic Remote Deploy

```bash
# Build locally, deploy remotely
nixos-rebuild switch \
  --flake .#hostname \
  --target-host root@192.168.1.100 \
  --build-host localhost

# Build and deploy on remote
nixos-rebuild switch \
  --flake .#hostname \
  --target-host root@192.168.1.100 \
  --build-host root@192.168.1.100
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `--target-host` | Machine to deploy to |
| `--build-host` | Machine to build on |
| `--use-remote-sudo` | Use sudo on target (for non-root) |
| `--fast` | Skip building boot entry |

### Non-Root Deployment

```bash
nixos-rebuild switch \
  --flake .#hostname \
  --target-host deploy@192.168.1.100 \
  --use-remote-sudo
```

### Wrapper Script

```bash
#!/usr/bin/env bash
# deploy.sh

HOST="${1:-myhost}"
TARGET="${2:-root@$HOST.local}"

nixos-rebuild switch \
  --flake ".#$HOST" \
  --target-host "$TARGET" \
  --build-host localhost \
  --use-substitutes
```

---

## Method 2: Colmena

Best for multi-host deployments with parallel execution.

### Installation

```bash
nix profile install nixpkgs#colmena
# Or use directly
nix run nixpkgs#colmena -- apply
```

### Flake Configuration

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { nixpkgs, colmena, ... }@inputs: {
    # Standard NixOS configurations
    nixosConfigurations = {
      web1 = nixpkgs.lib.nixosSystem { ... };
      web2 = nixpkgs.lib.nixosSystem { ... };
      db1 = nixpkgs.lib.nixosSystem { ... };
    };

    # Colmena configuration
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };

        # Default settings for all nodes
        specialArgs = { inherit inputs; };
      };

      defaults = { pkgs, ... }: {
        # Applied to all nodes
        environment.systemPackages = [ pkgs.vim ];
      };

      # Node definitions
      web1 = { name, nodes, pkgs, ... }: {
        deployment = {
          targetHost = "192.168.1.10";
          targetUser = "root";
          # Or use SSH config
          # targetHost = "web1.internal";
        };

        imports = [ ./hosts/web1 ];
      };

      web2 = { ... }: {
        deployment.targetHost = "192.168.1.11";
        imports = [ ./hosts/web2 ];
      };

      db1 = { ... }: {
        deployment = {
          targetHost = "192.168.1.20";
          tags = [ "database" ];  # For selective deployment
        };
        imports = [ ./hosts/db1 ];
      };
    };
  };
}
```

### Deployment Commands

```bash
# Deploy to all nodes
colmena apply

# Deploy to specific node
colmena apply --on web1

# Deploy to nodes with tag
colmena apply --on @database

# Build without deploying
colmena build

# Show deployment plan
colmena eval -E '{ nodes, ... }: builtins.attrNames nodes'

# Execute command on nodes
colmena exec --on web1 -- systemctl status nginx

# Deploy with local evaluation (faster for simple cases)
colmena apply --evaluator streaming
```

### Deployment Options

```nix
deployment = {
  # Target settings
  targetHost = "hostname-or-ip";
  targetPort = 22;
  targetUser = "root";

  # Build settings
  buildOnTarget = false;  # Build locally by default
  substituteOnDestination = true;  # Use binary cache on target

  # Deployment mode
  allowLocalDeployment = false;  # Prevent deploying to localhost
  replaceUnknownProfiles = true;

  # Tags for filtering
  tags = [ "web" "production" ];

  # Activation settings
  keys = {
    # Deploy secrets (alternative to sops-nix)
    "myapp.key" = {
      text = "secret-content";
      destDir = "/run/keys";
      user = "myapp";
      group = "myapp";
      permissions = "0400";
    };
  };
};
```

### Parallel Deployment

```bash
# Control parallelism
colmena apply --parallel 5

# Limit per-node parallelism
colmena apply --eval-node-limit 3
```

---

## Method 3: deploy-rs

Features automatic rollback on failure.

### Installation

```nix
# flake.nix
{
  inputs.deploy-rs.url = "github:serokell/deploy-rs";

  outputs = { self, nixpkgs, deploy-rs, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem { ... };

    deploy.nodes.myhost = {
      hostname = "192.168.1.100";
      sshUser = "root";

      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.myhost;
      };
    };

    # Validation
    checks = builtins.mapAttrs
      (system: deployLib: deployLib.deployChecks self.deploy)
      deploy-rs.lib;
  };
}
```

### Deployment

```bash
# Deploy all
nix run github:serokell/deploy-rs -- .

# Deploy specific node
nix run github:serokell/deploy-rs -- .#myhost

# Dry run
nix run github:serokell/deploy-rs -- . -- --dry-activate

# Skip checks
nix run github:serokell/deploy-rs -- . -- --skip-checks
```

### Rollback Safety

deploy-rs activates the new profile and waits for confirmation. If SSH connection fails (indicating a broken config), it automatically rolls back.

```nix
profiles.system = {
  # Activation timeout (seconds)
  activationTimeout = 240;

  # Confirmation timeout
  confirmTimeout = 30;

  # Magic rollback
  magicRollback = true;  # Default: true
};
```

### Multi-Profile Deployment

```nix
deploy.nodes.myhost = {
  hostname = "192.168.1.100";

  profiles = {
    # System profile (NixOS)
    system = {
      user = "root";
      path = deploy-rs.lib.x86_64-linux.activate.nixos
        self.nixosConfigurations.myhost;
    };

    # Home Manager profile
    home = {
      user = "myuser";
      path = deploy-rs.lib.x86_64-linux.activate.home-manager
        self.homeConfigurations.myuser;
    };

    # Custom profile
    myapp = {
      user = "myapp";
      path = deploy-rs.lib.x86_64-linux.activate.custom
        self.packages.x86_64-linux.myapp
        "./bin/activate";
    };
  };
};
```

---

## Method 4: nixos-anywhere

Install NixOS on any Linux machine remotely.

### Basic Usage

```bash
# Install NixOS using your flake config
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhost \
  root@192.168.1.100

# With disk formatting (DANGEROUS)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhost \
  --disk-encryption-keys /tmp/secret.key \
  root@192.168.1.100
```

### Disko Integration

```nix
# hosts/myhost/disko.nix
{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

---

## Cross-Architecture Deployment

Deploy to different architectures (e.g., build x86 → deploy ARM).

### Using binfmt

```nix
# On build machine
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

### Remote Building

```nix
# Use remote builder
nix.buildMachines = [{
  hostName = "builder.example.com";
  system = "aarch64-linux";
  maxJobs = 4;
  speedFactor = 2;
  supportedFeatures = [ "nixos-test" "big-parallel" ];
}];

nix.distributedBuilds = true;
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Build
        run: nix build .#nixosConfigurations.myhost.config.system.build.toplevel

      - name: Deploy
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_KEY }}
        run: |
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan myhost.example.com >> ~/.ssh/known_hosts

          nix run nixpkgs#colmena -- apply --on myhost
```

### GitLab CI

```yaml
# .gitlab-ci.yml
deploy:
  image: nixos/nix:latest
  script:
    - nix run nixpkgs#colmena -- apply
  only:
    - main
```

---

## Best Practices

### DO

1. **Test locally first**
   ```bash
   nixos-rebuild build --flake .#hostname
   ```

2. **Use `--build-host localhost`** for faster deploys with good network

3. **Tag hosts for selective deployment**
   ```bash
   colmena apply --on @production
   ```

4. **Keep rollback generations**
   ```nix
   boot.loader.systemd-boot.configurationLimit = 10;
   ```

5. **Monitor deployments**
   ```bash
   colmena exec -- journalctl -f
   ```

### DON'T

1. **Don't deploy without testing** - Always build first
2. **Don't deploy to all hosts at once** - Stage rollouts
3. **Don't disable rollback** - Keep magic rollback enabled
4. **Don't hardcode IPs** - Use SSH config or DNS

---

## Troubleshooting

### Connection Issues

```bash
# Test SSH
ssh -v root@target

# Check if nix-daemon is running on target
ssh root@target systemctl status nix-daemon
```

### Build Failures

```bash
# Build locally first
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Check for evaluation errors
nix eval .#nixosConfigurations.hostname.config.system.build.toplevel
```

### Activation Failures

```bash
# Check activation script
ssh root@target cat /nix/var/nix/profiles/system/activate

# Manual activation (for debugging)
ssh root@target /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Simple deploy | `nixos-rebuild switch --flake .#host --target-host root@ip` |
| Multi-host | `colmena apply` |
| Specific host | `colmena apply --on hostname` |
| Tagged hosts | `colmena apply --on @tag` |
| With rollback | `nix run github:serokell/deploy-rs` |
| Fresh install | `nix run github:nix-community/nixos-anywhere` |
| Build only | `colmena build` |
| Remote exec | `colmena exec -- command` |

## Confidence
0.95 - Patterns from official documentation and production usage.

## Sources
- [NixOS Manual - Deployment](https://nixos.org/manual/nixos/stable/#sec-changing-config)
- [Colmena](https://github.com/zhaofengli/colmena)
- [deploy-rs](https://github.com/serokell/deploy-rs)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [NixOS & Flakes Book - Remote Deployment](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)
