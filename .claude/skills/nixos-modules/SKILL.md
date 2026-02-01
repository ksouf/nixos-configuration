---
name: nixos-modules
description: NixOS module best practices. Triggers on: module creation, "mkOption", "mkIf", "mkEnableOption", "config =", module editing, imports, options
---

# NixOS Module Best Practices Skill

## MUST CHECK for every module edit

### 1. Function arguments MUST include `lib` and `...`
```nix
# BAD
{ config, pkgs }:

# GOOD
{ config, lib, pkgs, ... }:
```

### 2. Use correct priority functions
| Function | Priority | When |
|----------|----------|------|
| `lib.mkDefault` | 1000 | Fallback values |
| (direct) | 100 | Normal config |
| `lib.mkForce` | 50 | Override conflicts (use sparingly) |

### 3. Guard conflicting options
```nix
# BAD — conflict
services.pulseaudio.enable = true;
services.pipewire.enable = true;

# GOOD
services.pipewire.enable = true;
services.pulseaudio.enable = lib.mkForce false;
```

### 4. No hardcoded paths
```nix
# BAD
environment.variables.CONFIG = "/home/khaled/.config";

# GOOD
environment.variables.CONFIG = "${config.users.users.khaled.home}/.config";
```

### 5. Custom options need proper types
```nix
options.myModule = {
  enable = lib.mkEnableOption "my module";
  port = lib.mkOption {
    type = lib.types.port;
    default = 8080;
    description = "Port to listen on";
  };
};
```

### 6. Use `lib.mkIf` for conditional config
```nix
config = lib.mkIf cfg.enable {
  environment.systemPackages = [ cfg.package ];
};
```

### 7. Split large files (>200 lines)
```nix
imports = [
  ./services/nginx.nix
  ./services/postgresql.nix
];
```

## Module Template
```nix
{ config, lib, pkgs, ... }:
let cfg = config.myModule; in {
  options.myModule = {
    enable = lib.mkEnableOption "my module";
    package = lib.mkPackageOption pkgs "mypackage" { };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
```

## Known Conflicts in This Codebase
| Conflict | Resolution |
|----------|-----------|
| PulseAudio + PipeWire | `services.pulseaudio.enable = lib.mkForce false` |
| TLP + power-profiles-daemon | `services.power-profiles-daemon.enable = false` |
