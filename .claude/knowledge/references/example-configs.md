# Notable NixOS Configuration Examples

## Trigger
Looking for inspiration, patterns, or learning resources for NixOS configurations.

## Starter Templates

### Misterio77/nix-starter-configs

**Best for:** Beginners wanting clean, documented templates

**URL:** https://github.com/Misterio77/nix-starter-configs

**Features:**
- Minimal, standard, and full templates
- Well-documented
- NixOS + Home Manager
- Flake-based

**Structure:**
```
├── flake.nix
├── nixos/
│   └── configuration.nix
├── home-manager/
│   └── home.nix
└── modules/           # Custom modules
```

**Key Pattern:**
```nix
# Clean flake with separate NixOS and Home Manager
nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs outputs; };
  modules = [ ./nixos/configuration.nix ];
};

homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  extraSpecialArgs = { inherit inputs outputs; };
  modules = [ ./home-manager/home.nix ];
};
```

---

### dustinlyons/nixos-config

**Best for:** macOS + NixOS dual setup, step-by-step instructions

**URL:** https://github.com/dustinlyons/nixos-config

**Features:**
- Works on macOS and NixOS
- Detailed README with instructions
- Weekly flake auto-updates
- Optimized for simplicity

**Key Pattern:**
```nix
# Shared modules between macOS and NixOS
modules = [
  ./modules/shared.nix
] ++ (if isDarwin then [ ./modules/darwin ] else [ ./modules/nixos ]);
```

---

## Advanced Configurations

### ryan4yin/nix-config

**Best for:** Learning comprehensive NixOS patterns, multi-host

**URL:** https://github.com/ryan4yin/nix-config

**Author:** Creator of "NixOS & Nix Flakes Book"

**Features:**
- NixOS desktops (multiple DEs)
- macOS with nix-darwin
- Homelab servers (Kubernetes, Prometheus, Grafana)
- agenix for secrets
- Extensive documentation

**Structure:**
```
├── flake.nix
├── flake.lock
├── hosts/
│   ├── darwin/
│   ├── nixos-desktop/
│   └── nixos-server/
├── modules/
│   ├── base/
│   ├── desktop/
│   ├── server/
│   └── home/
├── home/
│   ├── base/
│   ├── desktop/
│   └── programs/
├── lib/               # Helper functions
├── outputs/           # Flake outputs organized
├── overlays/
└── secrets/
```

**Key Patterns:**

Helper function for hosts:
```nix
# lib/nixosSystem.nix
{ ... }:
hostname: nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = specialArgs // { inherit hostname; };
  modules = [
    ./hosts/${hostname}
    ./modules
  ];
}
```

---

### Misterio77/nix-config

**Best for:** Security-focused setup with impermanence

**URL:** https://github.com/Misterio77/nix-config

**Features:**
- Impermanence (ephemeral root)
- sops-nix with YubiKey
- BTRFS with encryption
- Hyprland desktop
- Full CI/CD

**Structure:**
```
├── flake.nix
├── hosts/
│   ├── common/
│   │   ├── global/      # All hosts
│   │   ├── optional/    # Opt-in features
│   │   └── users/       # User definitions
│   ├── hostname1/
│   └── hostname2/
├── home/
│   ├── misterio/        # User home configs
│   └── modules/         # Reusable home modules
├── modules/
│   ├── home-manager/    # Custom HM modules
│   └── nixos/           # Custom NixOS modules
├── overlays/
├── pkgs/                # Custom packages
└── templates/           # Flake templates
```

**Key Pattern - Impermanence:**
```nix
# Ephemeral root with persistent state
environment.persistence."/persist" = {
  hideMounts = true;
  directories = [
    "/var/log"
    "/var/lib/bluetooth"
    "/var/lib/nixos"
    "/etc/NetworkManager/system-connections"
  ];
  files = [
    "/etc/machine-id"
  ];
  users.misterio = {
    directories = [
      "Documents"
      "Projects"
      ".ssh"
      ".gnupg"
    ];
  };
};
```

---

### mitchellh/nixos-config

**Best for:** VM-based development workflow

**URL:** https://github.com/mitchellh/nixos-config

**Features:**
- macOS host with NixOS in VM
- Graphics passthrough
- Neovim-focused development
- Clean separation of concerns

**Key Insight:**
Uses macOS for graphical apps but does all development inside NixOS VM, getting the best of both worlds.

---

### gvolpe/nix-config

**Best for:** Haskell development, Wayland compositors

**URL:** https://github.com/gvolpe/nix-config

**Features:**
- Tiling Wayland compositor
- Haskell tooling
- Test in QEMU VM
- Comprehensive dotfiles

**Key Pattern - Testing:**
```bash
# Test configuration in VM before applying
nix build .#nixosConfigurations.tongfang-amd.config.system.build.vm
./result/bin/run-*-vm
```

---

### wimpysworld/nix-config

**Best for:** Multi-platform (NixOS + macOS), gaming

**URL:** https://github.com/wimpysworld/nix-config

**Features:**
- NixOS and nix-darwin
- Gaming configuration
- Featured on Linux Matters podcast
- Catppuccin theming

---

### srid/nixos-config

**Best for:** Minimal, flake-parts based setup

**URL:** https://github.com/srid/nixos-config

**Features:**
- KISS principle
- flake-parts
- nixos-unified template
- Minimal complexity

**Key Pattern - flake-parts:**
```nix
outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    flake = {
      nixosConfigurations.myhost = ...;
    };

    perSystem = { pkgs, ... }: {
      devShells.default = ...;
    };
  };
```

---

## Server-Focused

### nix-community/srvos

**Best for:** Production server configurations

**URL:** https://github.com/nix-community/srvos

**Features:**
- Production-ready defaults
- Hardware optimizations
- Mix-in modules
- Well-tested

**Usage:**
```nix
{
  imports = [
    srvos.nixosModules.server
    srvos.nixosModules.hardware-hetzner-cloud
  ];
}
```

---

## Pattern Summary

| Config | Multi-Host | Home Manager | Secrets | Impermanence | Complexity |
|--------|------------|--------------|---------|--------------|------------|
| nix-starter-configs | No | Yes | No | No | Low |
| dustinlyons | Yes | Yes | No | No | Low |
| ryan4yin | Yes | Yes | agenix | No | High |
| Misterio77 | Yes | Yes | sops-nix | Yes | High |
| mitchellh | No | Yes | No | No | Medium |
| gvolpe | Yes | Yes | No | No | Medium |
| srid | Yes | Yes | No | No | Low |

---

## Learning Path

### Beginner
1. Start with **nix-starter-configs** (standard template)
2. Study **dustinlyons** for step-by-step approach
3. Read **ryan4yin's NixOS & Flakes Book**

### Intermediate
4. Explore **gvolpe** for desktop patterns
5. Study **mitchellh** for development workflows
6. Add secrets with **sops-nix** or **agenix**

### Advanced
7. Implement impermanence like **Misterio77**
8. Build custom modules
9. Set up CI/CD for your config

---

## GitHub Topic

Explore more configurations: https://github.com/topics/nixos-configuration

Common tags:
- nixos
- nix-flakes
- home-manager
- dotfiles
- nix-darwin

---

## Community Resources

### Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix.dev](https://nix.dev/)
- [NixOS Wiki](https://wiki.nixos.org/)

### Books
- [NixOS & Nix Flakes Book](https://nixos-and-flakes.thiscute.world/) (by ryan4yin)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Zero to Nix](https://zero-to-nix.com/)

### Communities
- [NixOS Discourse](https://discourse.nixos.org/)
- [r/NixOS](https://reddit.com/r/NixOS)
- [NixOS Matrix](https://matrix.to/#/#nix:nixos.org)

## Confidence
0.95 - Well-known repositories with active maintenance.

## Sources
- GitHub repository analysis
- NixOS Discourse recommendations
- Community discussions
