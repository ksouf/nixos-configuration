# NixOS Security Checklist

Quick reference checklist for security audits.

## Critical (Must Fix)

### Secrets Management
- [ ] No plaintext passwords in .nix files
- [ ] No API keys/tokens in configuration
- [ ] Using sops-nix or agenix for secrets
- [ ] Secrets not in /nix/store

### Network Security
- [ ] `networking.firewall.enable = true`
- [ ] Only necessary ports open
- [ ] No `firewall.enable = false` anywhere

### SSH Security
- [ ] `PermitRootLogin = "no"`
- [ ] `PasswordAuthentication = false`
- [ ] `KbdInteractiveAuthentication = false`
- [ ] Fail2ban enabled (optional but recommended)

## High Priority

### Boot Security
- [ ] `boot.loader.systemd-boot.editor = false`
- [ ] LUKS encryption enabled (if applicable)

### Kernel Hardening
- [ ] `kernel.kptr_restrict = 2`
- [ ] `kernel.dmesg_restrict = 1`
- [ ] Hardened profile imported (optional)

### Service Isolation
- [ ] Services use `PrivateTmp = true`
- [ ] Services use `ProtectSystem = "strict"`
- [ ] `NoNewPrivileges = true` where applicable

## Medium Priority

### User Security
- [ ] Sudo requires password (or limited NOPASSWD)
- [ ] `security.pam.services.su.requireWheel = true`

### System Hardening
- [ ] `systemd.coredump.enable = false`
- [ ] Unnecessary kernel modules blacklisted
- [ ] AppArmor or SELinux considered

### Monitoring
- [ ] Audit logging enabled
- [ ] Log retention configured

## Low Priority (Recommended)

### Application Sandboxing
- [ ] Firejail for browsers
- [ ] Chromium SUID sandbox enabled

### Network Hardening
- [ ] DNS over TLS configured
- [ ] Outbound firewall (OpenSnitch) considered

### Updates
- [ ] Auto-upgrade configured or manual schedule
- [ ] Flake lock file updated regularly

---

## Quick Audit Commands

```bash
# Check firewall
grep -r "firewall.enable" /etc/nixos --include="*.nix"

# Check SSH
grep -r "PermitRootLogin\|PasswordAuthentication" /etc/nixos --include="*.nix"

# Check for secrets
grep -r 'password = "\|secret\|token\|apiKey' /etc/nixos --include="*.nix"

# Check boot editor
grep -r "editor = " /etc/nixos --include="*.nix"

# Systemd security analysis
systemd-analyze security | head -20
```

## Minimum Secure Configuration

```nix
{ lib, ... }:
{
  # Firewall
  networking.firewall.enable = true;

  # SSH
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
  };

  # Boot
  boot.loader.systemd-boot.editor = false;

  # Kernel
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
  };

  # Core dumps
  systemd.coredump.enable = false;
}
```
