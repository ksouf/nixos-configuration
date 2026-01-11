# Rule: NixOS Flakes Best Practices

## Trigger
Modifications to `flake.nix` or flake-related files

## Detection
Check for these flake issues:

### 1. Secrets in Flake Files
**Pattern:** Passwords, API keys, tokens in `flake.nix` or imported files
**Detection:** Strings matching `password`, `secret`, `token`, `api_key`, `apiKey`, `AWS_`, `GITHUB_TOKEN`
**Risk:** Flake contents are copied to world-readable /nix/store
**Severity:** CRITICAL

```nix
# NEVER DO THIS
{
  environment.variables.DB_PASSWORD = "supersecret";
}

# USE secret management instead (sops-nix, agenix)
```

### 2. Impure nixpkgs Import
**Pattern:** `import nixpkgs {}` without setting `config` or `overlays`
**Risk:** System reads from filesystem, breaking reproducibility
**Fix:** Explicitly set `config` and `overlays`

```nix
# BAD - impure
pkgs = import nixpkgs { system = "x86_64-linux"; };

# GOOD - explicit
pkgs = import nixpkgs {
  system = "x86_64-linux";
  config = { allowUnfree = true; };
  overlays = [ ];
};
```

### 3. Untracked Files Referenced
**Pattern:** Files referenced in flake but not added to git
**Detection:** Build errors "file not found"
**Fix:** `git add` new files before building

```bash
# After creating new-module.nix
git add new-module.nix
nix build  # Now works
```

### 4. Using `follows` Incorrectly
**Pattern:** Not using `follows` for shared inputs
**Risk:** Multiple nixpkgs versions, increased closure size
**Fix:** Use `follows` for common inputs

```nix
# BAD - home-manager uses its own nixpkgs
inputs = {
  nixpkgs.url = "...";
  home-manager.url = "...";
};

# GOOD - share nixpkgs
inputs = {
  nixpkgs.url = "...";
  home-manager = {
    url = "...";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### 5. Missing `systems` Specification
**Pattern:** Hard-coded system strings throughout flake
**Fix:** Use `systems` input or `flake-utils`

```nix
# BAD - repetitive
outputs = { nixpkgs, ... }: {
  packages.x86_64-linux.default = ...;
  packages.aarch64-linux.default = ...;
  devShells.x86_64-linux.default = ...;
  devShells.aarch64-linux.default = ...;
};

# GOOD - with flake-utils
outputs = { nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (system: {
    packages.default = ...;
    devShells.default = ...;
  });

# BETTER - with flake-parts
outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" ];
    perSystem = { pkgs, ... }: {
      packages.default = ...;
    };
  };
```

### 6. Outdated Lock File
**Pattern:** `flake.lock` not updated for months
**Detection:** Check `lastModified` timestamps in lock file
**Risk:** Missing security updates
**Fix:** Regular `nix flake update`

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

### 7. Not Specifying Hostname in nixosConfigurations
**Pattern:** Generic names like `default` or `system`
**Fix:** Use meaningful hostnames matching `/etc/hostname`

```nix
# BAD
nixosConfigurations.default = ...;

# GOOD
nixosConfigurations.my-laptop = nixpkgs.lib.nixosSystem {
  # ...
};
```

### 8. Missing specialArgs for Module Arguments
**Pattern:** Modules can't access flake inputs
**Fix:** Pass inputs via `specialArgs`

```nix
nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    pkgs-unstable = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  };
  modules = [ ./configuration.nix ];
};
```

## Flake Structure Template

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: for secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
```

## Security Checklist for Flakes

- [ ] No secrets in any .nix files
- [ ] `config` and `overlays` explicitly set on nixpkgs import
- [ ] Lock file updated within last 30 days
- [ ] All inputs use `follows` where appropriate
- [ ] Flake outputs tested with `nix flake check`

## Confidence
0.95 - Flake patterns from community documentation and best practices.

## References
- https://wiki.nixos.org/wiki/Flakes
- https://nixos-and-flakes.thiscute.world/
- https://flake.parts/
- https://determinate.systems/blog/nix-flakes-explained/
