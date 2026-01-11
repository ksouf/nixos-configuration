# Nix Language Patterns and Idioms

## Trigger
Any Nix code writing or review.

## Overview

Nix is a purely functional, lazily evaluated, dynamically typed language designed for package management. Think of it as "JSON with functions."

---

## Core Patterns

### 1. File Header Pattern

Every Nix file should start with a function that receives dependencies:

```nix
# Standard module header
{ config, pkgs, lib, ... }:

{
  # Configuration here
}
```

```nix
# Package/derivation header
{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  # ...
}
```

```nix
# Explicit dependencies (preferred for packages)
{ stdenv, fetchurl, openssl, zlib }:

stdenv.mkDerivation {
  # Dependencies are explicit
}
```

**Why:** Makes dependencies explicit, enables `callPackage` pattern, improves testability.

---

### 2. `let ... in` Pattern (Preferred)

Use `let` for local bindings instead of `rec`:

```nix
# GOOD - Clear, no recursion risk
let
  name = "mypackage";
  version = "1.0.0";
  src = fetchurl {
    url = "https://example.com/${name}-${version}.tar.gz";
    sha256 = "...";
  };
in
stdenv.mkDerivation {
  inherit name version src;
}
```

```nix
# BAD - rec can cause infinite recursion
rec {
  x = 1;
  y = x + 1;
  x = y;  # Infinite loop!
}
```

**Rule:** Always prefer `let ... in` over `rec { }`.

---

### 3. The `inherit` Keyword

Pull attributes from outer scope:

```nix
let
  name = "foo";
  version = "1.0";
in {
  # These are equivalent:
  name = name;
  version = version;

  # Shorthand:
  inherit name version;
}
```

Inherit from a set:

```nix
let
  mySet = { a = 1; b = 2; c = 3; };
in {
  inherit (mySet) a b;  # Brings a and b into scope
}
```

---

### 4. The `callPackage` Pattern

How nixpkgs auto-injects dependencies:

```nix
# In your package (mypackage.nix)
{ stdenv, fetchurl, openssl }:  # Declare what you need

stdenv.mkDerivation { ... }

# In all-packages.nix or overlay
mypackage = callPackage ./mypackage.nix { };

# callPackage automatically passes stdenv, fetchurl, openssl
# from the package set

# Override specific args:
mypackage = callPackage ./mypackage.nix {
  openssl = openssl_1_1;  # Use different version
};
```

---

### 5. The `@` Pattern (At Syntax)

Capture the whole argument set while destructuring:

```nix
# Capture full set as 'args'
{ pkgs, lib, config, ... }@args:

{
  # Can use both destructured names and full set
  myPackage = pkgs.hello;
  allArgs = args;  # { pkgs, lib, config, ... }
}
```

**Gotcha:** Default values don't appear in the captured set:

```nix
({ x ? 1 }@args: args) {}
# Returns: {} (not { x = 1; })
```

---

### 6. Avoid Top-Level `with`

```nix
# BAD - Where does mkIf come from?
with lib;
with pkgs;
{
  value = mkIf condition [ package1 package2 ];
}

# GOOD - Explicit origin
{ lib, pkgs, ... }:
let
  inherit (lib) mkIf mkDefault;
in {
  value = mkIf condition [ pkgs.package1 pkgs.package2 ];
}
```

**Why `with` is problematic:**
- Static analysis can't determine name origins
- Multiple `with` blocks create ambiguity
- Scoping is non-intuitive (`let` shadows `with`)

---

### 7. Attribute Access Patterns

```nix
# Direct access
mySet.attribute

# With default
mySet.attribute or "default"

# Safe nested access
mySet.nested.deep or null

# Check existence
if mySet ? attribute then ... else ...

# Dynamic attribute names
mySet.${variableName}
```

---

### 8. Function Patterns

```nix
# Simple function
square = x: x * x;

# Multiple arguments (curried)
add = x: y: x + y;

# Set pattern
greet = { name, greeting ? "Hello" }: "${greeting}, ${name}!";

# With extra attributes allowed
greet = { name, ... }: "Hello, ${name}!";

# Combining patterns
func = { name, ... }@args: { inherit name; extra = args; };
```

---

### 9. List Operations

```nix
let
  inherit (lib) map filter foldl' head tail length elem;

  numbers = [ 1 2 3 4 5 ];
in {
  # Map
  doubled = map (x: x * 2) numbers;  # [ 2 4 6 8 10 ]

  # Filter
  evens = filter (x: lib.mod x 2 == 0) numbers;  # [ 2 4 ]

  # Fold (reduce)
  sum = foldl' (acc: x: acc + x) 0 numbers;  # 15

  # Concatenation
  combined = numbers ++ [ 6 7 8 ];

  # Check membership
  hasThree = elem 3 numbers;  # true
}
```

---

### 10. Merging Attribute Sets

```nix
# Shallow merge (right wins)
{ a = 1; b = 2; } // { b = 3; c = 4; }
# Result: { a = 1; b = 3; c = 4; }

# WARNING: // replaces nested sets entirely!
{ nested = { x = 1; y = 2; }; } // { nested = { z = 3; }; }
# Result: { nested = { z = 3; }; }  # x and y are GONE!

# SOLUTION: Use recursiveUpdate for deep merge
lib.recursiveUpdate
  { nested = { x = 1; y = 2; }; }
  { nested = { z = 3; }; }
# Result: { nested = { x = 1; y = 2; z = 3; }; }
```

---

## Language Quirks and Gotchas

### String Quirks

```nix
# Indented strings strip leading whitespace, but preserve tabs
''
  spaces stripped
	tab preserved
''

# Multi-line strings
''
  Line 1
  Line 2
''
# Results in: "  Line 1\n  Line 2\n"

# Escape sequences in indented strings
''
  Use '''three quotes''' to escape
  Use ''${var} to escape interpolation
''
```

### `replaceStrings` Empty Match

```nix
builtins.replaceStrings ["" "e"] [" " "i"] "Hello"
# Result: " H i l l o "
# Empty string matches between EVERY character!
```

### `toString` Boolean Asymmetry

```nix
builtins.toString true   # "1"
builtins.toString false  # "" (empty string!)
```

### Integer Limits

```nix
# Valid range: -9223372036854775808 to 9223372036854775807
# Overflow wraps silently (no error!)

# No negative literals - parsed as subtraction
-9223372036854775808  # ERROR: positive part too large
-9223372036854775807 - 1  # Works

# No hex/octal/binary literals (use builtins.fromTOML workaround)
```

### Null Attribute Names

```nix
# Null names are excluded from sets
{ ${null} = 1; a = 2; }
# Result: { a = 2; }  (no null attribute)

# Useful for conditional attributes
{
  ${if condition then "key" else null} = value;
}
```

### `with` and `let` Priority

```nix
let x = 1;
in with { x = 2; }; x
# Result: 1 (let shadows with!)
```

### `import` is `eval`

```nix
# import loads AND evaluates a Nix file
# Not like traditional module imports!
import ./file.nix  # Returns the evaluated expression
```

---

## Path Handling

### Paths vs Strings

```nix
# Path (starts with . or /)
./relative/path
/absolute/path

# String (quoted)
"./this-is-a-string"
"/also-a-string"

# Paths are automatically copied to /nix/store when used
src = ./my-source;  # Copied to store, becomes /nix/store/xxx-my-source
```

### Reproducible Paths

```nix
# BAD - store path depends on parent directory name
src = ./.;  # /nix/store/xxx-source if in dir named "source"

# GOOD - explicit name for reproducibility
src = builtins.path {
  name = "my-project";
  path = ./.;
};
```

---

## Module-Specific Patterns

### Priority Functions

```nix
{ lib, ... }:
{
  # Default value (priority 1000) - easily overridden
  services.openssh.enable = lib.mkDefault true;

  # Normal assignment (priority 100)
  services.nginx.enable = true;

  # Force value (priority 50) - hard to override
  services.bluetooth.enable = lib.mkForce false;
}
```

### List Ordering

```nix
{ lib, ... }:
{
  # Normal (appended)
  environment.systemPackages = [ pkgs.vim ];

  # Prepend
  environment.systemPackages = lib.mkBefore [ pkgs.important ];

  # Append (explicit)
  environment.systemPackages = lib.mkAfter [ pkgs.less-important ];
}
```

### Option Types

```nix
{ lib, ... }:
{
  options.myModule = {
    enable = lib.mkEnableOption "my module";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowed users";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Freeform settings";
    };
  };
}
```

---

## Derivation Patterns

### Basic Derivation

```nix
{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "hello";
  version = "2.10";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/hello/hello-2.10.tar.gz";
    sha256 = "...";
  };

  # Implicit phases: unpack, patch, configure, build, install
}
```

### Override Patterns

```nix
# override - change derivation inputs
pkgs.hello.override {
  stdenv = pkgs.clangStdenv;
}

# overrideAttrs - change derivation attributes
pkgs.hello.overrideAttrs (old: {
  patches = (old.patches or []) ++ [ ./my-patch.patch ];

  postInstall = (old.postInstall or "") + ''
    mkdir -p $out/share/custom
  '';
})
```

---

## Debugging

### Trace Functions

```nix
# Print value and return it
builtins.trace "Debug message" value

# Print value representation
builtins.trace (builtins.toJSON mySet) result

# Conditional trace
lib.traceIf condition "message" value

# Trace with value
lib.traceVal value  # Prints and returns value

# Deep trace
lib.traceSeqN 2 value result  # Evaluate 2 levels deep before tracing
```

### REPL Exploration

```bash
# Enter REPL
nix repl

# Load nixpkgs
:l <nixpkgs>

# Explore
pkgs.hello
pkgs.hello.meta
:t pkgs.hello  # Show type
```

---

## Quick Reference

| Pattern | Use Case | Example |
|---------|----------|---------|
| `let ... in` | Local bindings | `let x = 1; in x + 1` |
| `inherit` | Pull from scope | `{ inherit name version; }` |
| `//` | Shallow merge | `a // b` |
| `lib.recursiveUpdate` | Deep merge | `lib.recursiveUpdate a b` |
| `or` | Default value | `set.key or "default"` |
| `?` | Has attribute | `if set ? key then ...` |
| `@args` | Capture full set | `{ x, y }@args:` |
| `...` | Allow extra attrs | `{ x, ... }:` |

## Confidence
1.0 - Core language patterns from official documentation.

## Sources
- [nix.dev - Nix Language](https://nix.dev/tutorials/nix-language.html)
- [NixOS Wiki - Language Quirks](https://wiki.nixos.org/wiki/Nix_Language_Quirks)
- [tazjin/nix-1p](https://github.com/tazjin/nix-1p)
- [Zero to Nix](https://zero-to-nix.com/concepts/nix-language/)
