# Rule: NixOS Deprecated Options

## Trigger
Any `.nix` file modification

## Detection
Check for these deprecated options and suggest modern alternatives:

| Deprecated | Replacement | Since |
|------------|-------------|-------|
| `hardware.pulseaudio.enable` | `services.pulseaudio.enable` | 24.05 |
| `users.extraUsers` | `users.users` | 23.05 |
| `users.extraGroups` | `users.groups` | 23.05 |
| `services.xserver.layout` | `services.xserver.xkb.layout` | 24.05 |
| `services.xserver.xkbVariant` | `services.xserver.xkb.variant` | 24.05 |
| `services.xserver.xkbOptions` | `services.xserver.xkb.options` | 24.05 |
| `sound.mediaKeys.enable` | Removed (handled by DE) | 24.05 |
| `networking.useDHCP` (global) | Per-interface DHCP | 23.05 |
| `nixpkgs.config.packageOverrides` | `nixpkgs.overlays` | Recommended |

## Fix
Replace deprecated option with modern equivalent. When the option is removed entirely (like `sound.mediaKeys.enable`), remove the line.

## Confidence
1.0 - These are official deprecations

## Examples
```nix
# Before
hardware.pulseaudio.enable = false;

# After
services.pulseaudio.enable = lib.mkForce false;
```
