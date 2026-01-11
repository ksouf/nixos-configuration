# NixOS Module System Deep Dive

## Trigger
Writing custom NixOS modules, understanding option behavior, or debugging module conflicts.

## Overview

The NixOS module system is the foundation that makes NixOS configurations composable and maintainable. It provides:

- **Option declarations** - Define what can be configured
- **Option definitions** - Set values for options
- **Automatic merging** - Combine multiple definitions intelligently
- **Type checking** - Validate configuration values

---

## Module Structure

Every NixOS module follows this structure:

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # Other modules to include
  ];

  options = {
    # Option declarations
  };

  config = {
    # Option definitions (the actual configuration)
  };
}
```

### Shorthand (Most Common)

When you don't declare custom options, you can omit `options` and `config`:

```nix
# This is a shorthand for config = { ... }
{ config, lib, pkgs, ... }:

{
  services.openssh.enable = true;
  environment.systemPackages = [ pkgs.vim ];
}
```

---

## Function Arguments

### Standard Arguments

| Argument | Description |
|----------|-------------|
| `config` | The final merged configuration (read-only) |
| `lib` | Nixpkgs library functions |
| `pkgs` | Package set |
| `options` | All option declarations |
| `modulesPath` | Path to nixpkgs/nixos/modules |

### Extra Arguments (specialArgs)

```nix
# In flake.nix
nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    myCustomArg = "value";
  };
  modules = [ ./configuration.nix ];
};

# In module
{ config, lib, pkgs, inputs, myCustomArg, ... }:
{
  # Can now use inputs and myCustomArg
}
```

### The `...` Pattern

Always include `...` to allow additional arguments:

```nix
# WRONG - breaks if new args are passed
{ config, pkgs }:

# CORRECT
{ config, pkgs, ... }:
```

---

## Option Types

### Basic Types

```nix
{ lib, ... }:

{
  options.myModule = {
    # Boolean
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    # String
    name = lib.mkOption {
      type = lib.types.str;
      default = "default-name";
    };

    # Integer
    count = lib.mkOption {
      type = lib.types.int;
      default = 0;
    };

    # Port (integer 0-65535)
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    # Path
    configFile = lib.mkOption {
      type = lib.types.path;
      default = /etc/myapp/config;
    };

    # Package
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myapp;
    };
  };
}
```

### Compound Types

```nix
{ lib, ... }:

{
  options.myModule = {
    # List of strings
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    # Attribute set of strings
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };

    # Nullable (can be null)
    optionalPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    # Either type
    portOrPath = lib.mkOption {
      type = lib.types.either lib.types.port lib.types.path;
    };

    # Enum (one of specific values)
    level = lib.mkOption {
      type = lib.types.enum [ "debug" "info" "warn" "error" ];
      default = "info";
    };

    # One of multiple types
    backend = lib.mkOption {
      type = lib.types.oneOf [
        lib.types.str
        (lib.types.attrsOf lib.types.str)
      ];
    };
  };
}
```

### Submodule Type

For nested configuration:

```nix
{ lib, ... }:

let
  serverOpts = { name, ... }: {
    options = {
      host = lib.mkOption {
        type = lib.types.str;
        description = "Server hostname";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 80;
      };

      ssl = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
in {
  options.myModule.servers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule serverOpts);
    default = {};
    description = "Server configurations";
  };

  # Usage:
  # myModule.servers = {
  #   web = { host = "web.example.com"; port = 443; ssl = true; };
  #   api = { host = "api.example.com"; port = 8080; };
  # };
}
```

---

## Option Declaration Helpers

### mkEnableOption

```nix
{ lib, ... }:

{
  options.services.myapp = {
    # Creates a boolean option with standard description
    enable = lib.mkEnableOption "MyApp service";

    # Equivalent to:
    # enable = lib.mkOption {
    #   type = lib.types.bool;
    #   default = false;
    #   description = "Whether to enable MyApp service.";
    # };
  };
}
```

### mkPackageOption

```nix
{ lib, pkgs, ... }:

{
  options.services.myapp = {
    # Creates a package option with override support
    package = lib.mkPackageOption pkgs "myapp" { };

    # With custom default from different attr path
    package = lib.mkPackageOption pkgs "myapp" {
      default = [ "myappPackages" "stable" ];
    };

    # Nullable package
    package = lib.mkPackageOption pkgs "myapp" {
      nullable = true;
    };
  };
}
```

### mkOption Full Form

```nix
{ lib, ... }:

{
  options.services.myapp.settings = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    example = lib.literalExpression ''
      {
        logLevel = "debug";
        maxConnections = "100";
      }
    '';
    description = lib.mdDoc ''
      Configuration settings for MyApp.

      See <https://myapp.example.com/docs> for available options.
    '';
  };
}
```

---

## Priority System

### Priority Levels

| Function | Priority | Description |
|----------|----------|-------------|
| `lib.mkOverride 0` | 0 | Highest priority |
| `lib.mkForce` | 50 | Force value |
| `lib.mkOverride 100` | 100 | Default for direct assignment |
| `lib.mkDefault` | 1000 | Low priority default |
| `lib.mkOverride 1500` | 1500 | Very low priority |

### How Priority Works

```nix
# Module A (priority 1000)
services.nginx.enable = lib.mkDefault true;

# Module B (priority 100 - direct assignment)
services.nginx.enable = false;  # This wins over mkDefault

# Module C (priority 50)
services.nginx.enable = lib.mkForce true;  # This wins over everything
```

### Custom Priority

```nix
# Set specific priority
services.foo.enable = lib.mkOverride 75 true;
```

### Checking What Set a Value

```bash
# In nix repl
:l <nixpkgs/nixos>
(evalModules { modules = [ ./configuration.nix ]; }).options.services.nginx.enable

# Shows definitions and priorities
```

---

## Merging Behavior

### Merging Lists

Lists are concatenated by default:

```nix
# Module A
environment.systemPackages = [ pkgs.vim ];

# Module B
environment.systemPackages = [ pkgs.git ];

# Result: [ pkgs.vim pkgs.git ]
```

Control order with mkBefore/mkAfter:

```nix
# Module A (order 500 - before)
environment.systemPackages = lib.mkBefore [ pkgs.important ];

# Module B (order 1000 - default)
environment.systemPackages = [ pkgs.normal ];

# Module C (order 1500 - after)
environment.systemPackages = lib.mkAfter [ pkgs.optional ];

# Result: [ pkgs.important pkgs.normal pkgs.optional ]
```

### Merging Attribute Sets

Attribute sets are merged recursively:

```nix
# Module A
services.nginx.virtualHosts."a.com" = { ... };

# Module B
services.nginx.virtualHosts."b.com" = { ... };

# Result: both virtual hosts present
```

### Conflict: Multiple Definitions

For non-mergeable types (strings, booleans), multiple definitions error:

```nix
# Module A
networking.hostName = "alpha";

# Module B
networking.hostName = "beta";

# ERROR: "The option 'networking.hostName' has conflicting definitions"
```

**Solution:** Use priority functions:

```nix
# Module A - default
networking.hostName = lib.mkDefault "alpha";

# Module B - overrides
networking.hostName = "beta";  # This wins
```

---

## Common Patterns

### Toggle Module Pattern

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myapp;
in {
  options.services.myapp = {
    enable = lib.mkEnableOption "MyApp";

    package = lib.mkPackageOption pkgs "myapp" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.myapp = {
      description = "MyApp Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/myapp --port ${toString cfg.port}";
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
```

### Conditional Configuration

```nix
{ config, lib, ... }:

{
  config = lib.mkMerge [
    # Always applied
    {
      services.base.enable = true;
    }

    # Only if X is enabled
    (lib.mkIf config.services.x.enable {
      services.y.enable = true;
    })

    # Only if condition
    (lib.mkIf (config.networking.hostName == "server") {
      services.nginx.enable = true;
    })
  ];
}
```

### Assertions and Warnings

```nix
{ config, lib, ... }:

let
  cfg = config.services.myapp;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.port >= 1024 || cfg.runAsRoot;
        message = "myapp: ports below 1024 require runAsRoot = true";
      }
      {
        assertion = cfg.database.host != "";
        message = "myapp: database.host must be set";
      }
    ];

    warnings =
      lib.optional (cfg.insecureMode)
        "myapp: insecureMode is enabled, this is not recommended for production";
  };
}
```

### Reading Config Values

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myapp;
in {
  options.services.myapp.configFile = lib.mkOption {
    type = lib.types.path;
    default = pkgs.writeText "myapp.conf" ''
      port = ${toString cfg.port}
      host = ${cfg.host}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${v}") cfg.settings)}
    '';
    defaultText = lib.literalExpression "generated from configuration";
  };
}
```

---

## Debugging Modules

### Check Option Value

```bash
# In nix repl
:l <nixpkgs/nixos>
config = (import <nixpkgs/nixos> { configuration = ./configuration.nix; }).config
config.services.nginx.enable

# Or from command line
nix eval '.#nixosConfigurations.myhost.config.services.nginx.enable'
```

### See Option Definition

```bash
nixos-option services.nginx.enable
```

### Trace Evaluation

```nix
{ config, lib, ... }:

{
  services.myapp = lib.traceVal config.services.myapp;

  # Or trace specific value
  environment.systemPackages = lib.traceValSeqN 2 config.environment.systemPackages;
}
```

### Find Option Definitions

```nix
# In nix repl
:l <nixpkgs/nixos>
options = (import <nixpkgs/nixos> { configuration = ./configuration.nix; }).options
options.services.nginx.enable.definitionsWithLocations
```

---

## Advanced Topics

### Freeform Modules

Allow arbitrary attributes:

```nix
{ lib, ... }:

{
  options.services.myapp = {
    enable = lib.mkEnableOption "myapp";

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.str;

        # Still can define specific options with types
        options.logLevel = lib.mkOption {
          type = lib.types.enum [ "debug" "info" "warn" "error" ];
          default = "info";
        };
      };
      default = {};
    };
  };

  # Usage:
  # services.myapp.settings = {
  #   logLevel = "debug";  # Typed
  #   arbitraryKey = "value";  # Freeform
  # };
}
```

### Recursive Options

```nix
{ lib, ... }:

let
  treeType = lib.types.attrsOf (lib.types.either lib.types.str treeType);
in {
  options.myTree = lib.mkOption {
    type = treeType;
    default = {};
  };
}
```

### Importing Modules Conditionally

```nix
{ config, lib, ... }:

{
  imports = [
    ./base.nix
  ] ++ lib.optionals config.services.xserver.enable [
    ./desktop.nix
  ];
}
```

---

## Module System vs Overlays

| Feature | Modules | Overlays |
|---------|---------|----------|
| Purpose | System configuration | Package modification |
| Scope | NixOS/Home Manager | Nixpkgs |
| Merging | Built-in | Manual |
| Options | Typed declarations | No type system |

---

## Quick Reference

### Common lib Functions

```nix
lib.mkIf condition config           # Conditional config
lib.mkMerge [ config1 config2 ]     # Merge configs
lib.mkDefault value                 # Low priority
lib.mkForce value                   # High priority
lib.mkBefore list                   # Prepend to list
lib.mkAfter list                    # Append to list
lib.mkOption { type; default; ... } # Declare option
lib.mkEnableOption "description"    # Boolean enable option
lib.mkPackageOption pkgs "name" {}  # Package option
lib.types.str                       # String type
lib.types.bool                      # Boolean type
lib.types.int                       # Integer type
lib.types.port                      # Port number type
lib.types.path                      # Path type
lib.types.package                   # Package type
lib.types.listOf type               # List type
lib.types.attrsOf type              # Attrset type
lib.types.nullOr type               # Nullable type
lib.types.enum [ values ]           # Enum type
lib.types.submodule { options; }    # Nested options
```

## Confidence
1.0 - Core module system from official NixOS documentation.

## Sources
- [NixOS Manual - Modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [nix.dev - Module System Deep Dive](https://nix.dev/tutorials/module-system/deep-dive.html)
- [Nixpkgs lib/modules.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/modules.nix)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system)
