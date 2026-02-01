---
name: nixos-nix-language
description: Detects Nix language antipatterns. Triggers on: any .nix file edit, "with", "rec", "import", "<nixpkgs>", "inherit", refactor, cleanup
---

# Nix Language Antipatterns Skill

## MUST CHECK after every .nix file edit

### 1. No top-level `with` statements
```nix
# BAD
with lib;
with pkgs;

# GOOD
let inherit (lib) mkIf mkDefault mkOption types; in
```
**Why:** Breaks static analysis, obscures name origins, causes shadowing bugs.

### 2. No `rec` — use `let ... in`
```nix
# BAD
rec { x = 1; y = x + 1; }

# GOOD
let x = 1; y = x + 1; in { inherit x y; }
```
**Why:** `rec` risks infinite recursion when names are shadowed.

### 3. No lookup paths `<...>`
```nix
# BAD
import <nixpkgs> {}

# GOOD (flake)
inputs.nixpkgs.legacyPackages.${system}
```
**Why:** Depends on $NIX_PATH, breaks reproducibility.

### 4. No unquoted URLs
```nix
# BAD
url = http://example.com/file.tar.gz;

# GOOD
url = "https://example.com/file.tar.gz";
```

### 5. Use `lib.recursiveUpdate` for nested merges
```nix
# DANGEROUS — nested keys lost
config = old // { nested = { newKey = 1; }; };

# SAFE
config = lib.recursiveUpdate old { nested = { newKey = 1; }; };
```

### 6. Always include `lib` when using lib functions
```nix
# BAD — runtime error
{ config, pkgs, ... }:
{ services.foo.enable = mkDefault true; }

# GOOD
{ config, lib, pkgs, ... }:
{ services.foo.enable = lib.mkDefault true; }
```

### 7. Use `builtins.path` for derivation sources
```nix
# BAD — unreproducible
src = ./.;

# GOOD
src = builtins.path { name = "my-project"; path = ./.; };
```

## Detection Commands
```bash
grep -rHn "^with " /etc/nixos --include="*.nix"
grep -rHn "rec {" /etc/nixos --include="*.nix"
grep -rHn "<nixpkgs>" /etc/nixos --include="*.nix"
grep -rHn "= http://" /etc/nixos --include="*.nix"
```
