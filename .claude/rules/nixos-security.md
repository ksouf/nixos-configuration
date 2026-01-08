# Rule: NixOS Security Best Practices

## Trigger
Any `.nix` file modification in security-related modules

## Detection
Check for these security issues:

### SSH Hardening
- `PermitRootLogin` should be `"no"` or `"prohibit-password"`
- `PasswordAuthentication` should be `false`
- `X11Forwarding` should be `false` unless needed

### Firewall
- `networking.firewall.enable` should be `true`
- Review open ports for necessity

### Boot Security
- `boot.loader.systemd-boot.editor` should be `false`

### Kernel Hardening
- `boot.kernel.sysctl."kernel.kptr_restrict"` should be `2`
- `boot.kernel.sysctl."kernel.dmesg_restrict"` should be `1`

## Fix
Add missing security configurations to `modules/security.nix`

## Confidence
0.9 - Security best practices, may need adjustment for specific use cases

## Examples
```nix
# SSH hardening
services.openssh.settings = {
  PermitRootLogin = "no";
  PasswordAuthentication = false;
};

# Firewall
networking.firewall.enable = true;
```
