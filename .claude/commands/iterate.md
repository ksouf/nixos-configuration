# Command: /iterate

Cycle 1 - Validate NixOS configuration. Syntax check, flake check, build test.

## Process

### Step 1: Syntax Check
```bash
echo "=== SYNTAX CHECK ==="
for f in $(git -C /etc/nixos diff --name-only HEAD -- "*.nix" 2>/dev/null); do
  if nix-instantiate --parse "/etc/nixos/$f" > /dev/null 2>&1; then
    echo "OK $f"
  else
    echo "FAIL $f - SYNTAX ERROR"
    nix-instantiate --parse "/etc/nixos/$f"
    exit 1
  fi
done
```

### Step 2: Flake Check
```bash
echo "=== FLAKE CHECK ==="
nix flake check /etc/nixos 2>&1 | head -30
```

### Step 3: Build Test
```bash
echo "=== BUILD TEST ==="
sudo nixos-rebuild build --flake /etc/nixos#hanibal
```

## Checklist
- [ ] All syntax checks pass
- [ ] Flake check passes
- [ ] Build succeeds

## Output
```
CYCLE 1 RESULTS
===============
Syntax: [PASS/FAIL]
Flake: [PASS/FAIL]
Build: [PASS/FAIL]

Status: Ready for Cycle 2 / Fix issues first
```

## If Failed
Fix issues before proceeding to Cycle 2 (/improve).

## Invocation
User says: "iterate", "/iterate", "validate", "check configuration"
