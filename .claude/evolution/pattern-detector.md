# Pattern Detector

This file defines patterns that Claude should detect in the NixOS configuration.

## NixOS-Specific Patterns

### Deprecated Options
- `hardware.pulseaudio` -> `services.pulseaudio`
- `users.extraUsers` -> `users.users`
- `services.xserver.layout` -> `services.xserver.xkb.layout`
- `sound.mediaKeys.enable` -> removed (handled by desktop environment)

### Common Issues
- Kernel parameters that block hardware detection (probe_mask, model=)
- Missing `lib` in module arguments when using `mkForce` or `mkDefault`
- Hardcoded paths instead of using `pkgs` references
- Non-existent options (e.g., `profiles.git.enable` vs `programs.git.enable`)

### Best Practices
- Always use `lib.mkForce` for overriding defaults, not direct assignment
- Include hardware firmware for the specific device
- Use unstable channel for frequently updated packages

## Pattern Detection Rules

When analyzing Nix files, look for:

1. **Deprecated syntax**: Check nixpkgs release notes for deprecated options
2. **Type mismatches**: Ensure option values match expected types
3. **Missing dependencies**: Verify all referenced modules are imported
4. **Security gaps**: Check for missing firewall rules, weak SSH config
5. **Performance issues**: Missing hardware optimizations for detected hardware
