# Rule: NixOS Module Best Practices

## Trigger
Any `.nix` file in modules/, desktop/, devices/, or shell/ directories

## Detection
Check for these module issues:

### 1. Missing `lib` in Arguments
**Pattern:** Function header without `lib` but using lib functions
**Detection:** File contains `mkDefault`, `mkForce`, `mkIf`, `mkOption`, `types.` without `lib` or `inherit (lib)`
**Fix:** Add `lib` to function arguments

```nix
# BAD
{ config, pkgs, ... }:

# GOOD
{ config, pkgs, lib, ... }:
```

### 2. Incorrect Priority Function Usage
**Pattern:** Using `mkForce` when `mkDefault` is appropriate
**Risk:** Prevents legitimate overrides
**Fix:** Use appropriate priority

| Function | Priority | When to Use |
|----------|----------|-------------|
| `mkDefault` | 1000 | Providing fallback values |
| (direct) | 100 | Normal configuration |
| `mkForce` | 50 | Must override conflicting modules |

```nix
# For optional defaults
services.openssh.enable = lib.mkDefault true;

# For required overrides (use sparingly)
hardware.pulseaudio.enable = lib.mkForce false;
```

### 3. Not Using `lib.mkOption` for Custom Options
**Pattern:** Options declared without proper types
**Fix:** Always use `mkOption` with types

```nix
# BAD
options.myModule.port = 8080;

# GOOD
options.myModule.port = lib.mkOption {
  type = lib.types.port;
  default = 8080;
  description = "Port to listen on";
};
```

### 4. Hardcoded Paths
**Pattern:** Absolute paths like `/home/user/...`
**Fix:** Use config values or derivations

```nix
# BAD
environment.variables.CONFIG = "/home/user/.config";

# GOOD
environment.variables.CONFIG = "${config.users.users.myuser.home}/.config";
```

### 5. Missing `...` in Function Arguments
**Pattern:** Module function without `...` causing "unexpected argument" errors
**Fix:** Add `...` to allow extra arguments

```nix
# BAD - breaks when new args are passed
{ config, pkgs }:

# GOOD
{ config, pkgs, ... }:
```

### 6. Conflicting Options Without Guards
**Pattern:** Setting options that conflict with other modules
**Detection:** Setting both `services.pulseaudio.enable` and `services.pipewire.enable`
**Fix:** Use guards or explicit disables

```nix
# BAD - conflict
services.pulseaudio.enable = true;
services.pipewire.enable = true;

# GOOD
services.pipewire.enable = true;
services.pulseaudio.enable = lib.mkForce false;
```

### 7. Inline Large Config Instead of Separate Files
**Pattern:** Single file > 200 lines with multiple unrelated sections
**Fix:** Split into logical modules using `imports`

```nix
# Use imports for organization
imports = [
  ./services/nginx.nix
  ./services/postgresql.nix
  ./users/admin.nix
];
```

## Module Structure Template

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.myModule;
in {
  options.myModule = {
    enable = lib.mkEnableOption "my module";

    package = lib.mkPackageOption pkgs "mypackage" { };

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
          };
        };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    # ...
  };
}
```

## Confidence
0.95 - Module patterns from NixOS manual and community conventions.

## References
- https://nixos.org/manual/nixos/stable/#sec-writing-modules
- https://nix.dev/tutorials/module-system/deep-dive.html
- https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
