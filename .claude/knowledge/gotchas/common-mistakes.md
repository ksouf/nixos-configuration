# Common NixOS Mistakes to Avoid

## Trigger
Any NixOS configuration work, especially for newcomers.

## Beginner Mistakes

### 1. Using `nix-env` for Package Installation

**Problem:** Using `nix-env -iA` to install packages defeats the purpose of declarative configuration.

```bash
# DON'T DO THIS
nix-env -iA nixos.firefox
```

**Why it's bad:**
- Loses track of installed packages
- Can't reproduce system state
- Conflicts with declarative config
- No rollback integration

**Solution:** Add packages declaratively:
```nix
# In configuration.nix or home-manager
environment.systemPackages = with pkgs; [
  firefox
];
```

---

### 2. Not Running Garbage Collection

**Problem:** Old generations accumulate, filling disk space.

**Detection:**
```bash
# Check disk usage
du -sh /nix/store
# List generations
nix-env --list-generations
```

**Solution:** Enable automatic GC:
```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};

# Also enable store optimization
nix.optimise.automatic = true;
```

**Manual cleanup:**
```bash
sudo nix-collect-garbage -d  # Delete old generations
nix-store --optimise         # Deduplicate store
```

---

### 3. Using `rec` Instead of `let`

**Problem:** `rec` creates hard-to-debug infinite recursion when shadowing names.

```nix
# DANGEROUS - can cause infinite recursion
rec {
  x = 1;
  y = x + 1;
  x = y;  # Oops! Shadows x, infinite loop
}
```

**Solution:** Use `let ... in`:
```nix
# SAFE
let
  x = 1;
  y = x + 1;
in {
  inherit x y;
}
```

---

### 4. Top-Level `with` Statements

**Problem:** `with (import <nixpkgs> {});` obscures name origins and breaks static analysis.

```nix
# DON'T DO THIS
with (import <nixpkgs> {});
with lib;
{
  # Where does mkIf come from? lib? pkgs? Who knows!
  config = mkIf something { ... };
}
```

**Why it's bad:**
- Static analysis tools can't reason about the code
- Multiple `with` blocks make origin unclear
- Non-intuitive scoping rules

**Solution:** Use explicit bindings:
```nix
{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkDefault;
in {
  config = mkIf something { ... };
}
```

---

### 5. Using `<nixpkgs>` Lookup Paths

**Problem:** Lookup paths depend on `$NIX_PATH`, breaking reproducibility.

```nix
# DON'T DO THIS - impure
{ pkgs ? import <nixpkgs> {} }:
```

**Why it's bad:**
- Different machines have different `$NIX_PATH`
- Builds aren't reproducible
- Can't guarantee versions

**Solution:** Pin nixpkgs with flakes:
```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }: {
    # Pinned and reproducible
  };
}
```

---

## Module Mistakes

### 6. Forgetting `lib` in Module Arguments

**Problem:** Using `mkForce`, `mkDefault`, etc. without importing `lib`.

```nix
# WRONG - lib not available
{ config, pkgs, ... }:
{
  services.openssh.enable = mkDefault true;  # Error!
}
```

**Solution:** Always include `lib`:
```nix
{ config, pkgs, lib, ... }:
{
  services.openssh.enable = lib.mkDefault true;
}
```

---

### 7. Not Understanding Priority Functions

**Problem:** Confusion about which value wins when options are set multiple places.

**Priority Order (lower number = higher priority):**
| Function | Priority | Use Case |
|----------|----------|----------|
| `lib.mkForce` | 50 | Override everything |
| Direct assignment | 100 | Normal setting |
| `lib.mkDefault` | 1000 | Provide fallback |

```nix
# Module A
services.foo.enable = lib.mkDefault true;  # Priority 1000

# Module B
services.foo.enable = false;  # Priority 100, WINS

# Module C (if needed to override B)
services.foo.enable = lib.mkForce true;  # Priority 50, WINS
```

---

### 8. Hardcoding Paths

**Problem:** Using absolute paths that may not exist on other systems.

```nix
# DON'T DO THIS
environment.variables.MY_CONFIG = "/home/user/.config/myapp";
```

**Solution:** Use proper path references:
```nix
# Use config values
environment.variables.MY_CONFIG = "${config.users.users.myuser.home}/.config/myapp";

# Or for store paths
environment.variables.MY_SCRIPT = "${pkgs.writeScript "myscript" ''...'')}";
```

---

## Security Mistakes

### 9. Storing Secrets in Configuration

**Problem:** Secrets in `.nix` files end up in world-readable `/nix/store`.

```nix
# NEVER DO THIS
services.myservice.password = "supersecret123";
```

**Solution:** Use secret management:
```nix
# With sops-nix
sops.secrets.myservice-password = {
  sopsFile = ./secrets.yaml;
};
services.myservice.passwordFile = config.sops.secrets.myservice-password.path;
```

---

### 10. Disabling Firewall Without Understanding

**Problem:** `networking.firewall.enable = false` exposes all services.

```nix
# DANGEROUS
networking.firewall.enable = false;
```

**Solution:** Keep firewall enabled, open specific ports:
```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 80 443 ];
};
```

---

## Build Mistakes

### 11. Not Using Binary Cache

**Problem:** Building everything from source wastes hours.

**Solution:** Ensure cache is configured:
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
};
```

---

### 12. Confusing `buildInputs` vs `nativeBuildInputs`

**Problem:** Wrong category causes cross-compilation failures.

| Attribute | Runs On | Example |
|-----------|---------|---------|
| `nativeBuildInputs` | Build machine | `cmake`, `pkg-config` |
| `buildInputs` | Target machine | `openssl`, `zlib` |

```nix
mkDerivation {
  nativeBuildInputs = [ cmake pkg-config ];  # Build tools
  buildInputs = [ openssl zlib ];             # Libraries to link
}
```

---

## Flake Mistakes

### 13. Forgetting to `git add` New Files

**Problem:** Flakes only see tracked files; new files are invisible.

```bash
# Created new-module.nix but flake doesn't see it
nix build  # Error: file not found
```

**Solution:** Add files to git:
```bash
git add new-module.nix
nix build  # Works now
```

---

### 14. Not Setting `nixpkgs.config` Explicitly

**Problem:** Nixpkgs can read impure config from filesystem.

**Solution:** Set explicitly in flake:
```nix
nixpkgs.legacyPackages.x86_64-linux.extend (final: prev: {
  config = {
    allowUnfree = true;
  };
})

# Or in NixOS config
nixpkgs.config = {
  allowUnfree = true;
};
```

---

## Tooling to Catch Mistakes

### statix - Nix Linter
```bash
nix run nixpkgs#statix -- check .
nix run nixpkgs#statix -- fix .   # Auto-fix some issues
```

Detects:
- Useless `with`
- Empty `let` blocks
- Manual `inherit from`
- Deprecated syntax

### nixfmt - Formatter
```bash
nix run nixpkgs#nixfmt-classic -- *.nix
```

### nix-diff - Compare Derivations
```bash
nix run nixpkgs#nix-diff -- /nix/store/old... /nix/store/new...
```

---

## Quick Reference Checklist

Before committing:
- [ ] No `nix-env` usage
- [ ] `lib` included in module arguments
- [ ] No `rec` (use `let ... in`)
- [ ] No top-level `with`
- [ ] No `<nixpkgs>` lookup paths
- [ ] No plaintext secrets
- [ ] Firewall enabled
- [ ] New files `git add`ed
- [ ] `statix check` passes

## Confidence
1.0 - These are well-documented community consensus mistakes.

## Sources
- [nix.dev Best Practices](https://nix.dev/guides/best-practices.html)
- [NixOS Discourse](https://discourse.nixos.org/)
- [DEV Community - 5 Common Mistakes](https://dev.to/beckmateo/5-very-common-mistakes-a-beginner-should-avoid-when-trying-nixos-for-the-first-time-to-truly-start-2j3n)
