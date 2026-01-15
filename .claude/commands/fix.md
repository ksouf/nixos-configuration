# Command: /fix

Auto-fix known NixOS issues (deprecations, conflicts).

## Process

### Step 1: Scan for Issues
Run detection for all known patterns:
```bash
cd /etc/nixos

echo "=== DEPRECATIONS ==="
grep -rHn "services\.xserver\.layout" . --include="*.nix" 2>/dev/null
grep -rHn "services\.xserver\.xkbOptions" . --include="*.nix" 2>/dev/null
grep -rHn "sound\.enable = true" . --include="*.nix" 2>/dev/null
grep -rHn "hardware\.pulseaudio\.enable = true" . --include="*.nix" 2>/dev/null
grep -rHn "users\.extraUsers" . --include="*.nix" 2>/dev/null
grep -rHn "gnome3\." . --include="*.nix" 2>/dev/null

echo "=== CONFLICTS ==="
PULSE=$(grep -rl "pulseaudio\.enable = true" . --include="*.nix" 2>/dev/null)
PIPE=$(grep -rl "pipewire\.enable = true" . --include="*.nix" 2>/dev/null)
[ -n "$PULSE" ] && [ -n "$PIPE" ] && echo "CONFLICT: PulseAudio + PipeWire"

TLP=$(grep -rl "tlp\.enable = true" . --include="*.nix" 2>/dev/null)
PPD=$(grep -rl "power-profiles-daemon\.enable = true" . --include="*.nix" 2>/dev/null)
[ -n "$TLP" ] && [ -n "$PPD" ] && echo "CONFLICT: TLP + power-profiles-daemon"
```

### Step 2: Categorize by Confidence

**High Confidence (Auto-apply):**
- XKB migration (layout, options, variant)
- users/groups rename
- gnome3 -> gnome
- Disable pulseaudio when pipewire enabled
- Disable power-profiles-daemon when tlp enabled

**Medium Confidence (Show diff, ask):**
- sound.enable -> PipeWire migration
- Security hardening suggestions

**Low Confidence (Document only):**
- Complex refactoring
- Architecture changes

### Step 3: Apply Fixes

For each high-confidence fix:
1. Show before/after
2. Apply the change
3. Run syntax check
4. Log to fixes.jsonl

```json
{
  "ts": "[ISO8601]",
  "file": "[path]",
  "issue": "[description]",
  "fix": "[description]",
  "confidence": "high",
  "before": "[original line]",
  "after": "[fixed line]",
  "success": true
}
```

### Step 4: Validate
```bash
nix-instantiate --parse [modified-file]
nix flake check
```

## Fix Templates

### XKB Migration
```nix
# Before
services.xserver.layout = "fr";
services.xserver.xkbOptions = "ctrl:nocaps";

# After
services.xserver.xkb = {
  layout = "fr";
  options = "ctrl:nocaps";
};
```

### sound.enable Removal
```nix
# Before
sound.enable = true;

# After (for Hyprland - needs sound support)
# Remove sound.enable entirely, ensure PipeWire is configured elsewhere
# OR replace with PipeWire config if not already present
```

### PulseAudio + PipeWire Conflict
```nix
# Ensure pulseaudio disabled when using pipewire
hardware.pulseaudio.enable = lib.mkForce false;
```

## Output
```
FIX RESULTS
===========
Issues found: [N]
Auto-fixed: [N]
Need review: [N]
Skipped: [N]

Changes:
  [file]: [description]
  [file]: [description]

Validation: [PASS/FAIL]
```

## Invocation
User says: "fix", "/fix", "auto-fix", "fix issues"
