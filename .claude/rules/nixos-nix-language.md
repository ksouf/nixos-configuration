# Rule: Nix Language Antipatterns

## Trigger
Any `.nix` file modification

## Detection
Check for these Nix language antipatterns:

### 1. Using `rec` Instead of `let`
**Pattern:** `rec {` or `rec{`
**Risk:** Infinite recursion when shadowing names
**Fix:** Convert to `let ... in` pattern

```nix
# BAD
rec {
  x = 1;
  y = x + 1;
}

# GOOD
let
  x = 1;
  y = x + 1;
in { inherit x y; }
```

### 2. Top-Level `with` Statements
**Pattern:** `with .*;` at file start (outside function body)
**Risk:** Breaks static analysis, obscures name origins
**Fix:** Use explicit `let` bindings or `inherit`

```nix
# BAD
with lib;
with pkgs;

# GOOD
{ lib, pkgs, ... }:
let
  inherit (lib) mkIf mkDefault;
in
```

### 3. Lookup Paths (`<...>`)
**Pattern:** `<nixpkgs>`, `<nixos>`, `<...>`
**Risk:** Depends on $NIX_PATH, breaks reproducibility
**Fix:** Use flake inputs or pinned fetchTarball

```nix
# BAD
import <nixpkgs> {}

# GOOD (flake)
inputs.nixpkgs.legacyPackages.${system}

# GOOD (non-flake)
import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.11.tar.gz") {}
```

### 4. Unquoted URLs
**Pattern:** Bare URLs like `http://...` without quotes
**Risk:** Deprecated syntax, parsing issues
**Fix:** Quote all URLs

```nix
# BAD
fetchurl { url = http://example.com/file.tar.gz; }

# GOOD
fetchurl { url = "https://example.com/file.tar.gz"; }
```

### 5. Shallow Merge for Nested Sets
**Pattern:** `//` on sets with nested attributes
**Risk:** Nested attributes are replaced, not merged
**Fix:** Use `lib.recursiveUpdate` for deep merge

```nix
# DANGEROUS - nested keys lost
config = oldConfig // { nested = { newKey = 1; }; }

# SAFE
config = lib.recursiveUpdate oldConfig { nested = { newKey = 1; }; }
```

### 6. Missing `lib` in Module Arguments
**Pattern:** Module using `mkDefault`, `mkForce`, `mkIf` without `lib` in args
**Risk:** Runtime error
**Fix:** Add `lib` to function arguments

```nix
# BAD
{ config, pkgs, ... }:
{
  services.foo.enable = mkDefault true;  # Error!
}

# GOOD
{ config, pkgs, lib, ... }:
{
  services.foo.enable = lib.mkDefault true;
}
```

### 7. Relative Path Without `builtins.path`
**Pattern:** `src = ./.;` in derivation
**Risk:** Store path depends on directory name
**Fix:** Use `builtins.path` with explicit name

```nix
# BAD - unreproducible
src = ./.;

# GOOD
src = builtins.path {
  name = "my-project-src";
  path = ./.;
};
```

## Fix
Replace antipatterns with recommended alternatives as shown above.

## Confidence
1.0 - These are documented best practices from nix.dev and NixOS Wiki.

## References
- https://nix.dev/guides/best-practices.html
- https://wiki.nixos.org/wiki/Nix_Language_Quirks
