---
name: nixos-deprecations
description: Detects and fixes NixOS deprecations. Triggers on: audit, deprecated options found, "old", "update", "migrate", "upgrade", version changes
---

# NixOS Deprecation Handling

## Detection Commands
```bash
grep -rHn "services\.xserver\.layout" /etc/nixos --include="*.nix"
grep -rHn "services\.xserver\.xkbOptions" /etc/nixos --include="*.nix"
grep -rHn "services\.xserver\.xkbVariant" /etc/nixos --include="*.nix"
grep -rHn "users\.extraUsers" /etc/nixos --include="*.nix"
grep -rHn "users\.extraGroups" /etc/nixos --include="*.nix"
grep -rHn "sound\.enable" /etc/nixos --include="*.nix"
grep -rHn "hardware\.pulseaudio\.enable = true" /etc/nixos --include="*.nix"
grep -rHn "gnome3\." /etc/nixos --include="*.nix"
grep -rHn "hardware\.opengl\.enable" /etc/nixos --include="*.nix"
grep -rHn "nvidiaPatches" /etc/nixos --include="*.nix"
```

## Deprecation Table

| Deprecated | Replacement | Since |
|------------|-------------|-------|
| `services.xserver.layout` | `services.xserver.xkb.layout` | 24.05 |
| `services.xserver.xkbVariant` | `services.xserver.xkb.variant` | 24.05 |
| `services.xserver.xkbOptions` | `services.xserver.xkb.options` | 24.05 |
| `users.extraUsers` | `users.users` | 23.11 |
| `users.extraGroups` | `users.groups` | 23.11 |
| `sound.enable = true` | PipeWire config | 24.05 |
| `hardware.pulseaudio.enable = true` | `services.pipewire` | 24.05 |
| `gnome3.*` | `gnome.*` | 23.05 |
| `nixfmt` | `nixfmt-classic` | 24.05 |
| `1password-cli` | `_1password-cli` | 24.05 |
| `sound.mediaKeys.enable` | Removed (handled by DE) | 24.05 |
| `hardware.opengl.enable` | `hardware.graphics.enable` | 24.11 |
| `programs.hyprland.nvidiaPatches` | Removed | 24.05 |

## Auto-Fix Patterns

### XKB (24.05)
```nix
# Before
services.xserver.layout = "us";
services.xserver.xkbOptions = "caps:escape";

# After
services.xserver.xkb = {
  layout = "us";
  options = "caps:escape";
};
```

### Users (23.11)
```nix
# Before
users.extraUsers.khaled = { ... };

# After
users.users.khaled = { ... };
```

### Audio (24.05)
```nix
# Before
sound.enable = true;
hardware.pulseaudio.enable = true;

# After
hardware.pulseaudio.enable = false;
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
  wireplumber.enable = true;
};
```

### GNOME (23.05)
```nix
# Before
gnome3.nautilus

# After
gnome.nautilus
```

## Severity Levels

| Level | Action |
|-------|--------|
| Critical | Will fail to build - fix immediately |
| Warning | Deprecated, will break in future |
| Info | Newer alternative available |
