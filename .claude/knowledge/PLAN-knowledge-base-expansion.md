# NixOS Knowledge Base Expansion Plan

## Research Summary

Comprehensive internet research completed on 2026-01-11, covering:
- 15+ web searches across authoritative sources
- 12+ detailed page fetches from nix.dev, NixOS Wiki, NixOS Discourse, and community guides
- Analysis of notable community configurations (mitchellh, Misterio77, ryan4yin, gvolpe)

## Proposed Knowledge Base Structure

```
.claude/knowledge/
├── fundamentals/
│   ├── nix-language.md           # Nix language patterns, idioms, quirks
│   ├── module-system.md          # NixOS module architecture deep-dive
│   └── flakes.md                 # Flakes best practices and patterns
│
├── patterns/
│   ├── modularization.md         # Directory structures, imports, organization
│   ├── overlays.md               # Overlay patterns and anti-patterns
│   ├── multi-host.md             # Multi-machine configuration patterns
│   ├── home-manager.md           # Home Manager integration patterns
│   └── devshells.md              # Development environment patterns
│
├── security/
│   ├── hardening-guide.md        # Comprehensive security hardening
│   ├── systemd-hardening.md      # Service-level hardening
│   ├── secrets-management.md     # sops-nix, agenix, git-crypt comparison
│   └── security-checklist.md     # Quick security audit checklist
│
├── operations/
│   ├── deployment.md             # Remote deployment (colmena, deploy-rs, nixos-rebuild)
│   ├── testing.md                # VM testing, integration tests
│   ├── upgrades.md               # Version migrations, channel management
│   ├── binary-cache.md           # Caching strategies and Cachix
│   └── garbage-collection.md     # Store maintenance
│
├── hardware/
│   ├── laptop-optimization.md    # Power management, TLP, battery
│   ├── containers.md             # Docker, Podman, OCI containers
│   └── impermanence.md           # Ephemeral root patterns
│
├── gotchas/
│   ├── language-quirks.md        # Nix language pitfalls
│   ├── common-mistakes.md        # Beginner mistakes to avoid
│   └── antipatterns.md           # Patterns to avoid
│
└── references/
    ├── example-configs.md        # Notable community configurations
    ├── tools-ecosystem.md        # Useful tools (statix, nixfmt, etc.)
    └── resources.md              # Links to documentation and guides
```

---

## Detailed Content Plans

### 1. fundamentals/nix-language.md

**Content:**
- File header pattern (`{ pkgs ? import <nixpkgs> {} }:`)
- `let ... in` vs `rec { }` (prefer let)
- `with` scope issues and alternatives
- `inherit` keyword usage
- `@` pattern for function arguments
- `callPackage` pattern explanation
- Lazy evaluation benefits
- String interpolation rules
- Path handling and `builtins.path`

**Quirks Section:**
- `with` and `let` priority conflicts
- Default values not included in `@args`
- Indented string whitespace trimming
- `replaceStrings` empty string behavior
- `toString` boolean asymmetry (true="1", false="")
- 64-bit integer overflow (silent wrap)
- No negative literals (parsed as subtraction)
- Null attribute names excluded from sets

**Sources:**
- [nix.dev tutorials](https://nix.dev/tutorials/nix-language.html)
- [NixOS Wiki - Language Quirks](https://wiki.nixos.org/wiki/Nix_Language_Quirks)
- [tazjin/nix-1p](https://github.com/tazjin/nix-1p)

---

### 2. fundamentals/module-system.md

**Content:**
- Module structure: `{ config, pkgs, lib, ... }:`
- Three sections: `imports`, `options`, `config`
- Option declaration vs definition
- Type system (`types.str`, `types.listOf`, etc.)
- `mkOption`, `mkEnableOption`, `mkPackageOption`
- Priority functions:
  - `lib.mkDefault` (priority 1000) - baseline
  - Direct assignment (priority 100) - mid-level
  - `lib.mkForce` (priority 50) - override
- List ordering: `lib.mkBefore` (500), `lib.mkAfter` (1500)
- Module merging semantics
- `evalModules` for custom module systems
- Input/output separation pattern

**Sources:**
- [NixOS & Flakes Book - Module System](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system)
- [nix.dev - Module System Deep Dive](https://nix.dev/tutorials/module-system/deep-dive.html)
- [NixOS Wiki - Modules](https://wiki.nixos.org/wiki/NixOS_modules)

---

### 3. fundamentals/flakes.md

**Content:**
- Flake structure (`flake.nix`, `flake.lock`)
- Inputs specification and pinning
- Outputs schema:
  - `nixosConfigurations`
  - `homeConfigurations`
  - `packages`
  - `devShells`
  - `overlays`
  - `checks`
- System-specific outputs with `forAllSystems`
- `flake.lock` management
- Security: never store secrets in flakes
- Git requirement: only tracked files included
- Enabling flakes: `nix.settings.experimental-features`

**flake-parts Section:**
- Benefits over raw flakes
- `perSystem` for system-specific outputs
- Module composition
- Migration from flake-utils

**Sources:**
- [Flakes - NixOS Wiki](https://wiki.nixos.org/wiki/Flakes)
- [flake.parts](https://flake.parts/)
- [Determinate Systems - Flakes Explained](https://determinate.systems/blog/nix-flakes-explained/)

---

### 4. patterns/modularization.md

**Content:**
- Recommended directory structure:
```
├── flake.nix
├── hosts/
│   ├── hostname1/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── hostname2/
├── modules/
│   ├── security.nix
│   ├── networking.nix
│   └── services/
├── home/
│   ├── programs/
│   └── shell/
└── overlays/
```
- Import patterns (explicit vs implicit)
- `default.nix` convention for directories
- Splitting by concern vs by host
- Shared vs host-specific configuration
- Notable examples:
  - [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
  - [Misterio77/nix-config](https://github.com/Misterio77/nix-config)
  - [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config)

---

### 5. patterns/overlays.md

**Content:**
- Overlay function signature: `final: prev: { }`
- `final` vs `prev` semantics
- Common use cases:
  - Version pinning
  - Patch application
  - Build flag modification
  - Adding packages from other sources
- Application methods:
  - `nixpkgs.overlays` in configuration
  - `import nixpkgs { overlays = [...]; }`
  - `.extend` for chaining
- Avoiding infinite recursion (use `prev` not `final`)
- `.override` vs `.overrideAttrs`
- Scoped overrides (`.overrideScope` for GNOME, etc.)
- Language-specific: Python, Rust, R packages

**Anti-patterns:**
- Using `~/.config/nixpkgs/overlays/` (impure)
- Overlaying everything (cache invalidation)

---

### 6. security/hardening-guide.md

**Content:**

**Kernel Hardening:**
```nix
imports = [ <nixpkgs/nixos/modules/profiles/hardened.nix> ];
```
- Enables hardened Linux kernel
- Memory allocator protection
- Module loading restrictions
- AppArmor

**SSH Hardening:**
```nix
services.openssh.settings = {
  PermitRootLogin = "no";
  PasswordAuthentication = false;
  KbdInteractiveAuthentication = false;
  X11Forwarding = false;
};
```

**Firewall:**
```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ ];
  allowedUDPPorts = [ ];
};
```

**Boot Security:**
```nix
boot.loader.systemd-boot.editor = false;
```

**Kernel Sysctl:**
```nix
boot.kernel.sysctl = {
  "kernel.kptr_restrict" = 2;
  "kernel.dmesg_restrict" = 1;
  "net.core.bpf_jit_harden" = 2;
};
```

**Additional:**
- Firejail for browser sandboxing
- ClamAV for antivirus
- OpenSnitch for outbound filtering
- Chromium SUID sandbox
- Disable coredumps: `systemd.coredump.enable = false`

**Sources:**
- [NixOS Wiki - Security](https://wiki.nixos.org/wiki/Security)
- [Solene's Hardening Guide](https://dataswamp.org/~solene/2022-01-13-nixos-hardened.html)
- [nix-mineral](https://github.com/cynicsketch/nix-mineral)

---

### 7. security/secrets-management.md

**Content:**

| Tool | Encryption | Pros | Cons | Best For |
|------|-----------|------|------|----------|
| **agenix** | age/SSH | Simple, uses SSH keys | No templates | Simple setups |
| **sops-nix** | age/GPG/KMS | Flexible, templates | More complex | Production |
| **git-crypt** | GPG | Simple Git integration | Secrets in store | Quick & dirty |
| **ragenix** | age | Rust, fast | Less mature | agenix alternative |

**sops-nix Setup:**
```nix
sops.secrets.my-secret = {
  sopsFile = ./secrets/secrets.yaml;
  owner = "myuser";
};
```

**agenix Setup:**
```nix
age.secrets.my-secret = {
  file = ./secrets/secret.age;
  owner = "myuser";
};
```

**Key Points:**
- Secrets decrypted at runtime in `/run/secrets`
- Use SSH host keys for machine identity
- `ssh-to-age` for key conversion
- Never store in `/nix/store` unencrypted

**Sources:**
- [NixOS Wiki - Secret Management Comparison](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [agenix](https://github.com/ryantm/agenix)

---

### 8. security/systemd-hardening.md

**Content:**
- Using `systemd-analyze security myService`
- Key hardening options:
```nix
systemd.services.myservice.serviceConfig = {
  PrivateTmp = true;
  PrivateDevices = true;
  ProtectSystem = "strict";
  ProtectHome = true;
  NoNewPrivileges = true;
  CapabilityBoundingSet = "";
  RestrictNamespaces = true;
  RestrictRealtime = true;
  MemoryDenyWriteExecute = true;
};
```
- `RootDirectory` for chroot
- Network access with chroot
- Resource limits with `cgroups`

---

### 9. operations/deployment.md

**Content:**

**nixos-rebuild (built-in):**
```bash
nixos-rebuild switch --flake .#host \
  --target-host root@192.168.1.1 \
  --build-host localhost
```

**colmena:**
```nix
# In flake.nix outputs
colmena = {
  meta.nixpkgs = import nixpkgs { system = "x86_64-linux"; };
  host1 = { ... }: {
    deployment.targetHost = "192.168.1.1";
  };
};
```
```bash
colmena apply
```

**deploy-rs:**
- Automatic rollback on failure
- Profile-based deployment
- Non-root deployments

**Prerequisites:**
- SSH key authentication
- Known hosts configured
- `users.users.<user>.openssh.authorizedKeys.keys`

---

### 10. operations/testing.md

**Content:**
- NixOS VM tests with `testers.runNixOSTest`
- Test structure:
```nix
testers.runNixOSTest {
  name = "my-test";
  nodes.machine = { ... }: {
    services.myservice.enable = true;
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("myservice")
    machine.succeed("curl localhost:8080")
  '';
}
```
- Interactive testing: `driverInteractive`
- Multi-machine tests
- Adding to flake `checks`
- Caching test results

**Sources:**
- [nix.dev - VM Testing](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html)

---

### 11. operations/binary-cache.md

**Content:**
- Default cache: `cache.nixos.org`
- Configuring substituters:
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://mycache.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:..."
    "mycache.cachix.org-1:..."
  ];
};
```
- Self-hosted with `nix-serve`
- Cachix for teams
- Post-build hooks for auto-upload
- `nix.gc` for cleanup
- `nix.optimise` for deduplication

---

### 12. hardware/laptop-optimization.md

**Content:**
- TLP configuration:
```nix
services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    START_CHARGE_THRESH_BAT0 = 40;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };
};
```
- Conflict: TLP vs power-profiles-daemon
- Alternative: auto-cpufreq
- Thermald for Intel CPUs
- Power management: `powerManagement.enable`
- SSD optimization: fstrim, zram
- Intel microcode updates

---

### 13. hardware/containers.md

**Content:**
- Docker:
```nix
virtualisation.docker.enable = true;
users.users.myuser.extraGroups = [ "docker" ];
```
- Podman (rootless):
```nix
virtualisation.podman = {
  enable = true;
  dockerCompat = true;
  defaultNetwork.settings.dns_enabled = true;
};
```
- OCI containers:
```nix
virtualisation.oci-containers.containers.myapp = {
  image = "myimage:latest";
  ports = [ "8080:80" ];
};
```
- Native NixOS containers (systemd-nspawn)
- `compose2nix` for docker-compose conversion

---

### 14. hardware/impermanence.md

**Content:**
- Concept: ephemeral root, persistent `/nix` and `/persist`
- Benefits: no configuration drift, clean system
- BTRFS setup with subvolumes
- impermanence module:
```nix
environment.persistence."/persist" = {
  directories = [
    "/var/log"
    "/var/lib/bluetooth"
  ];
  files = [
    "/etc/machine-id"
  ];
};
```
- Boot-time rollback with systemd

**Sources:**
- [nix-community/impermanence](https://github.com/nix-community/impermanence)
- [Erase Your Darlings](https://grahamc.com/blog/erase-your-darlings/)

---

### 15. gotchas/common-mistakes.md

**Content:**

**Beginner Mistakes:**
1. Using `nix-env` instead of declarative config
2. Not running garbage collection
3. Not reading documentation
4. Using `rec` instead of `let`
5. Top-level `with` statements
6. Using `<nixpkgs>` (impure)

**Configuration Mistakes:**
1. Forgetting `lib` in module arguments
2. Hardcoding paths
3. Not pinning nixpkgs
4. Mixing channels inconsistently
5. Secrets in `/nix/store`

**Build Mistakes:**
1. Not using binary cache
2. Circular dependencies
3. Missing `nativeBuildInputs` vs `buildInputs`

**Tools:**
- `statix` - Nix linter
- `nixfmt-classic` - Formatter
- `nix-diff` - Compare derivations

---

### 16. references/example-configs.md

**Notable Configurations:**

| Repository | Highlights |
|------------|-----------|
| [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) | macOS host + NixOS VM workflow |
| [Misterio77/nix-config](https://github.com/Misterio77/nix-config) | Impermanence, sops-nix, YubiKey |
| [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) | Multi-host, desktops + servers, author of NixOS & Flakes Book |
| [gvolpe/nix-config](https://github.com/gvolpe/nix-config) | Wayland compositor, Haskell focus |
| [wimpysworld/nix-config](https://github.com/wimpysworld/nix-config) | Multi-platform (NixOS + Darwin) |
| [srid/nixos-config](https://github.com/srid/nixos-config) | KISS, flake-parts based |
| [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) | Templates for beginners |
| [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config) | macOS + NixOS, beginner-friendly |

---

## New Rules to Add

Based on research, add these rules to `.claude/rules/`:

### nixos-modules.md
- Always include `lib` in module arguments
- Use `mkDefault`/`mkForce` appropriately
- Avoid `rec` attribute sets
- Use `let ... in` instead

### nixos-flakes.md
- Pin all inputs
- Never store secrets in flakes
- Set `config` and `overlays` explicitly on import
- Use `builtins.path` with `name` for reproducibility

### nixos-nix-language.md
- Avoid top-level `with`
- Quote all URLs
- Avoid lookup paths `<...>`
- Use `lib.recursiveUpdate` for nested merges

---

## Implementation Priority

### Phase 1 (High Priority)
1. `gotchas/common-mistakes.md` - Prevent issues
2. `security/hardening-guide.md` - Critical for production
3. `fundamentals/nix-language.md` - Foundation

### Phase 2 (Medium Priority)
4. `patterns/modularization.md` - Organization
5. `security/secrets-management.md` - Production needs
6. `fundamentals/module-system.md` - Deep understanding

### Phase 3 (Lower Priority)
7. `operations/deployment.md`
8. `hardware/laptop-optimization.md`
9. `patterns/overlays.md`
10. Remaining files

---

## Integration with Existing System

### Update Auditor Agent
Add checks for:
- `rec` usage (warn)
- Top-level `with` (warn)
- Unpinned `<nixpkgs>` (error)
- Missing `lib` in module args (warn)
- Secrets in plain text (critical)

### Update Rules
Add new rule files:
- `nixos-nix-language.md`
- `nixos-modules.md`
- `nixos-flakes.md`

### Update CLAUDE.md
Add reference to knowledge base in CLAUDE.md best practices section.

---

## Sources Referenced

### Official Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nix.dev](https://nix.dev/)
- [NixOS Wiki](https://wiki.nixos.org/)

### Community Resources
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [Zero to Nix](https://zero-to-nix.com/)
- [NixOS Discourse](https://discourse.nixos.org/)

### Tools
- [Cachix](https://www.cachix.org)
- [flake-parts](https://flake.parts/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [agenix](https://github.com/ryantm/agenix)
- [impermanence](https://github.com/nix-community/impermanence)
- [colmena](https://github.com/zhaofengli/colmena)
- [deploy-rs](https://github.com/serokell/deploy-rs)
- [statix](https://github.com/nerdypepper/statix)

### Security
- [nix-mineral](https://github.com/cynicsketch/nix-mineral)
- [Solene's Hardening Guide](https://dataswamp.org/~solene/2022-01-13-nixos-hardened.html)
