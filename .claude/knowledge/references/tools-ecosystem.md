# NixOS Tools Ecosystem

## Trigger
Looking for tools to improve NixOS development, linting, formatting, or workflows.

---

## Code Quality

### statix - Nix Linter

Detects antipatterns and suggests fixes.

```bash
# Install
nix profile install nixpkgs#statix

# Check for issues
statix check .

# Auto-fix issues
statix fix .

# Single file
statix check configuration.nix
```

**Detects:**
- Useless `with` expressions
- Empty `let` blocks
- Deprecated `...` patterns
- Manual `inherit` from expressions
- Legacy `let { }` syntax
- Redundant parentheses

---

### nixfmt - Code Formatter

Official Nix formatter.

```bash
# Install (nixfmt-classic for older style)
nix profile install nixpkgs#nixfmt-classic
# Or nixfmt-rfc-style for new style
nix profile install nixpkgs#nixfmt-rfc-style

# Format file
nixfmt configuration.nix

# Format in place
nixfmt -i configuration.nix

# Check only (CI)
nixfmt --check configuration.nix
```

---

### deadnix - Dead Code Finder

Finds unused variables and expressions.

```bash
nix profile install nixpkgs#deadnix

# Find dead code
deadnix .

# Auto-fix
deadnix -e .
```

---

### nil / nixd - Language Servers

**nil** - Minimal, fast LSP:
```bash
nix profile install nixpkgs#nil
```

**nixd** - Feature-rich LSP with option completion:
```bash
nix profile install nixpkgs#nixd
```

**VS Code setup:**
```json
{
  "nix.enableLanguageServer": true,
  "nix.serverPath": "nil",
  "nix.serverSettings": {
    "nil": {
      "formatting": { "command": ["nixfmt"] }
    }
  }
}
```

---

## Build & Development

### nix-direnv

Automatic environment loading with caching.

```nix
# In home-manager
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

```bash
# In project directory
echo "use flake" > .envrc
direnv allow
# Environment loads automatically on cd
```

---

### devenv

Higher-level development environments.

```bash
# Install
nix profile install nixpkgs#devenv

# Init project
devenv init

# Enter shell
devenv shell
```

```nix
# devenv.nix
{ pkgs, ... }: {
  packages = [ pkgs.git ];

  languages.python = {
    enable = true;
    version = "3.11";
  };

  services.postgres.enable = true;

  pre-commit.hooks = {
    nixfmt.enable = true;
    ruff.enable = true;
  };
}
```

---

### nix-output-monitor (nom)

Better build output visualization.

```bash
nix profile install nixpkgs#nix-output-monitor

# Use instead of nix build
nom build .#package

# With nixos-rebuild
nixos-rebuild switch |& nom
```

---

### nvd - Nix Version Diff

Compare system generations or closures.

```bash
nix profile install nixpkgs#nvd

# Compare current to previous generation
nvd diff /run/current-system /run/booted-system

# Compare specific generations
nvd diff /nix/var/nix/profiles/system-{41,42}-link
```

---

### nix-diff

Deep comparison of derivations.

```bash
nix profile install nixpkgs#nix-diff

# Compare two derivations
nix-diff /nix/store/xxx-foo /nix/store/yyy-foo
```

---

## Search & Discovery

### nix search

```bash
# Search packages
nix search nixpkgs firefox

# Search with more details
nix search nixpkgs#firefox --json | jq

# Search all flake outputs
nix flake show nixpkgs --json | jq
```

---

### nix-index

Faster package search with file contents.

```bash
nix profile install nixpkgs#nix-index

# Build index (takes time)
nix-index

# Find package by file
nix-locate bin/firefox

# Find command
nix-locate --top-level -w /bin/docker
```

**With comma (command-not-found replacement):**
```bash
nix profile install nixpkgs#comma

# Run command without installing
, cowsay hello
```

---

### manix

Search NixOS/Home Manager options.

```bash
nix profile install nixpkgs#manix

# Search options
manix "services.nginx"
manix "home.packages"
```

---

## Deployment

### colmena

Multi-host deployment tool.

```bash
nix profile install nixpkgs#colmena

# Deploy to all hosts
colmena apply

# Deploy to specific host
colmena apply --on host1

# Build without deploying
colmena build
```

---

### deploy-rs

Profile-based deployment with rollback.

```bash
# Deploy
nix run github:serokell/deploy-rs -- .

# Dry run
nix run github:serokell/deploy-rs -- . -- --dry-activate
```

---

### nixos-anywhere

Install NixOS remotely on any Linux.

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhost \
  root@192.168.1.1
```

---

## Secrets

### sops

Edit encrypted secrets.

```bash
nix profile install nixpkgs#sops

# Edit secrets file
sops secrets.yaml

# Decrypt to stdout
sops -d secrets.yaml
```

---

### agenix

Manage age-encrypted secrets.

```bash
nix run github:ryantm/agenix -- -e secret.age
nix run github:ryantm/agenix -- -r  # Rekey all
```

---

### ssh-to-age

Convert SSH keys to age keys.

```bash
nix profile install nixpkgs#ssh-to-age

# User key
ssh-to-age < ~/.ssh/id_ed25519.pub

# Host key
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

---

## Flake Helpers

### flake-parts

Modular flake framework.

```nix
{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShell { };
      };
    };
}
```

---

### flake-utils

System iteration helper (legacy, prefer flake-parts).

```nix
{
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.default = ...;
    });
}
```

---

### flake-compat

Use flakes without flakes enabled.

```nix
# default.nix
(import (fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz") {
  src = ./.;
}).defaultNix
```

---

## Caching

### Cachix

Binary cache hosting.

```bash
nix profile install nixpkgs#cachix

# Login
cachix authtoken <token>

# Push build results
nix build | cachix push mycache

# Use cache
cachix use mycache
```

---

### attic

Self-hosted binary cache.

```bash
# Run server
nix run github:zhaofengli/attic#attic-server

# Push to cache
attic push mycache /nix/store/...
```

---

## Testing

### nixos-test

VM-based integration testing.

```nix
# In flake.nix
checks.x86_64-linux.mytest = pkgs.testers.runNixOSTest {
  name = "mytest";
  nodes.machine = { ... }: {
    services.myservice.enable = true;
  };
  testScript = ''
    machine.wait_for_unit("myservice")
    machine.succeed("curl localhost:8080")
  '';
};
```

```bash
# Run tests
nix flake check

# Interactive testing
nix build .#checks.x86_64-linux.mytest.driverInteractive
./result/bin/nixos-test-driver
```

---

## Documentation

### nix-doc

Inline documentation viewer.

```bash
nix profile install nixpkgs#nix-doc

# View function docs
nix-doc lib.mkIf
```

---

### nixos-option

Query NixOS option values.

```bash
nixos-option services.nginx.enable
nixos-option networking.firewall.allowedTCPPorts
```

---

## Quick Reference

| Task | Tool |
|------|------|
| Lint code | `statix check` |
| Format code | `nixfmt` |
| Find dead code | `deadnix` |
| Language server | `nil` or `nixd` |
| Auto-load env | `direnv` + `nix-direnv` |
| Better build output | `nom` |
| Compare generations | `nvd diff` |
| Search packages | `nix search` or `nix-index` |
| Search options | `manix` |
| Deploy multi-host | `colmena` |
| Manage secrets | `sops` or `agenix` |
| Cache builds | `cachix` |
| Test config | `nixos-test` |

---

## Pre-commit Hooks

```nix
# Using devenv or git-hooks.nix
{
  pre-commit.hooks = {
    nixfmt.enable = true;
    statix.enable = true;
    deadnix.enable = true;
  };
}
```

---

## CI/CD Integration

```yaml
# GitHub Actions
- uses: DeterminateSystems/nix-installer-action@main
- uses: DeterminateSystems/magic-nix-cache-action@main
- run: nix flake check
- run: nix build .#nixosConfigurations.myhost.config.system.build.toplevel
```

## Confidence
0.95 - Well-established tools in the NixOS ecosystem.

## Sources
- Nixpkgs package search
- NixOS Discourse tool recommendations
- GitHub repositories
