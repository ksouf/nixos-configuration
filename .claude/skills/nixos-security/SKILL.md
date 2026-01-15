---
name: nixos-security
description: NixOS security hardening. Triggers on: "security", "ssh", "firewall", "password", "secret", audit, hardening
---

# NixOS Security

## Security Scan
```bash
# Plaintext passwords (CRITICAL)
grep -rHn 'password = "' /etc/nixos --include="*.nix"

# SSH config
grep -rHn "PermitRootLogin\|PasswordAuthentication" /etc/nixos --include="*.nix"

# Firewall
grep -rHn "firewall\.enable" /etc/nixos --include="*.nix"

# Boot security
grep -rHn "systemd-boot\.editor" /etc/nixos --include="*.nix"
```

## Security Hardening Template

### SSH
```nix
services.openssh = {
  enable = true;
  settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    X11Forwarding = false;
    AllowTcpForwarding = false;
    AllowAgentForwarding = false;
  };
};
```

### Firewall
```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ ];
  allowedUDPPorts = [ ];
};
```

### Boot
```nix
boot.loader.systemd-boot.editor = false;
```

### Kernel
```nix
boot.kernel.sysctl = {
  "kernel.kptr_restrict" = 2;
  "kernel.dmesg_restrict" = 1;
  "kernel.yama.ptrace_scope" = 1;
};
```

## Password Handling
Never use plaintext passwords. Use:
```nix
users.users.username = {
  hashedPasswordFile = "/path/to/hashed-password";
  # Or
  hashedPassword = "$6$..."; # From mkpasswd
};
```

## Secrets Management Options

### sops-nix
```nix
# In flake.nix inputs
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};

# In configuration
sops.secrets.my-secret = {
  sopsFile = ./secrets/secrets.yaml;
};
```

### agenix
```nix
# In flake.nix inputs
agenix.url = "github:ryantm/agenix";

# In configuration
age.secrets.my-secret.file = ./secrets/my-secret.age;
```

## Common Security Mistakes
- Secrets in nix files (copied to world-readable /nix/store)
- Firewall disabled for "convenience"
- SSH password authentication enabled
- Running unnecessary services as root
- Boot editor enabled (allows root access)

## Security Checklist
- [ ] No plaintext secrets in any .nix files
- [ ] Firewall enabled with minimal open ports
- [ ] SSH hardened (no root login, no password auth)
- [ ] Boot editor disabled
- [ ] Kernel hardening applied
- [ ] Core dumps restricted
- [ ] Services run as unprivileged users where possible
