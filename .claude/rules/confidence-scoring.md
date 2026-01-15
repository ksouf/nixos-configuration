# Confidence Scoring System

Track confidence for each pattern/rule to determine auto-apply vs ask.

## Formula
```
confidence = (successes / attempts) * min(attempts / 5, 1.0)
```

This formula:
- Rewards success rate
- Requires minimum 5 attempts for full confidence
- New patterns start with low effective confidence

## Thresholds

| Confidence | Action |
|------------|--------|
| HIGH (>0.8) | Auto-apply without asking |
| MEDIUM (0.5-0.8) | Apply with notification |
| LOW (<0.5) | Ask for confirmation |
| NEW (0 attempts) | Always ask |

## Tracking Format

In `.claude/memory/metrics.jsonl`:
```json
{
  "ts": "2026-01-15T10:00:00+01:00",
  "type": "confidence_update",
  "pattern": "D1-xkb-layout",
  "attempts": 15,
  "successes": 15,
  "confidence": 1.0
}
```

## Pattern Categories

### Deprecation Fixes (D*)
| Pattern | Description | Initial Confidence |
|---------|-------------|-------------------|
| D1 | xkb.layout migration | 1.0 (official) |
| D2 | xkb.options migration | 1.0 (official) |
| D3 | xkb.variant migration | 1.0 (official) |
| D4 | extraUsers -> users | 1.0 (official) |
| D5 | extraGroups -> groups | 1.0 (official) |
| D6 | sound.enable removal | 0.9 (context-dependent) |
| D7 | pulseaudio -> pipewire | 0.8 (may need config) |
| D8 | gnome3 -> gnome | 1.0 (simple rename) |

### Security Fixes (SEC*)
| Pattern | Description | Initial Confidence |
|---------|-------------|-------------------|
| SEC1 | PermitRootLogin = "no" | 0.9 |
| SEC2 | PasswordAuthentication = false | 0.9 |
| SEC3 | firewall.enable = true | 0.8 |
| SEC4 | systemd-boot.editor = false | 0.9 |

### Conflict Resolutions (CON*)
| Pattern | Description | Initial Confidence |
|---------|-------------|-------------------|
| CON1 | pulseaudio + pipewire | 1.0 (disable pulse) |
| CON2 | tlp + power-profiles-daemon | 1.0 (disable ppd) |

## Confidence Updates

After each fix application:
```bash
# Load current confidence
PATTERN="D1-xkb-layout"
CURRENT=$(grep "\"pattern\":\"$PATTERN\"" .claude/memory/metrics.jsonl | tail -1)

# Parse values
ATTEMPTS=$(echo "$CURRENT" | grep -o '"attempts":[0-9]*' | cut -d: -f2)
SUCCESSES=$(echo "$CURRENT" | grep -o '"successes":[0-9]*' | cut -d: -f2)

# Update based on result
if [ "$FIX_SUCCESS" = "true" ]; then
  SUCCESSES=$((SUCCESSES + 1))
fi
ATTEMPTS=$((ATTEMPTS + 1))

# Calculate new confidence
# confidence = (successes / attempts) * min(attempts / 5, 1.0)
RATE=$(echo "scale=2; $SUCCESSES / $ATTEMPTS" | bc)
MATURITY=$(echo "scale=2; if ($ATTEMPTS / 5 > 1) 1 else $ATTEMPTS / 5" | bc)
CONFIDENCE=$(echo "scale=2; $RATE * $MATURITY" | bc)

# Log update
echo "{\"ts\":\"$(date -Is)\",\"type\":\"confidence_update\",\"pattern\":\"$PATTERN\",\"attempts\":$ATTEMPTS,\"successes\":$SUCCESSES,\"confidence\":$CONFIDENCE}" >> .claude/memory/metrics.jsonl
```

## Auto-Promotion

When a pattern reaches HIGH confidence after 5+ successful applications:
1. Log promotion event to evolution.jsonl
2. Update rule documentation to note "auto-apply"
3. Consider creating skill if pattern is common

```json
{
  "ts": "2026-01-15T10:00:00+01:00",
  "event": "pattern_promoted",
  "pattern": "D1-xkb-layout",
  "from_confidence": 0.7,
  "to_confidence": 0.95,
  "reason": "5 consecutive successes"
}
```

## Demotion

When a fix fails:
1. Decrement confidence
2. If confidence drops below 0.5, require confirmation
3. If confidence drops below 0.3, review pattern definition

## Usage in Fix Command

```bash
apply_fix() {
  local pattern=$1
  local confidence=$(get_confidence "$pattern")

  if [ "$(echo "$confidence > 0.8" | bc)" -eq 1 ]; then
    # Auto-apply
    echo "Auto-applying $pattern (confidence: $confidence)"
    do_fix
  elif [ "$(echo "$confidence > 0.5" | bc)" -eq 1 ]; then
    # Notify and apply
    echo "Applying $pattern (confidence: $confidence)"
    show_diff
    do_fix
  else
    # Ask first
    echo "Low confidence fix: $pattern ($confidence)"
    show_diff
    read -p "Apply? [y/N] " confirm
    [ "$confirm" = "y" ] && do_fix
  fi
}
```

## Initial Confidence Values

Pre-seeded patterns with established confidence:
```json
{"ts":"2026-01-15T00:00:00+01:00","type":"confidence_init","pattern":"D1-xkb-layout","attempts":10,"successes":10,"confidence":1.0}
{"ts":"2026-01-15T00:00:00+01:00","type":"confidence_init","pattern":"D4-extraUsers","attempts":10,"successes":10,"confidence":1.0}
{"ts":"2026-01-15T00:00:00+01:00","type":"confidence_init","pattern":"D8-gnome3","attempts":10,"successes":10,"confidence":1.0}
{"ts":"2026-01-15T00:00:00+01:00","type":"confidence_init","pattern":"CON1-audio","attempts":10,"successes":10,"confidence":1.0}
{"ts":"2026-01-15T00:00:00+01:00","type":"confidence_init","pattern":"CON2-power","attempts":10,"successes":10,"confidence":1.0}
```
