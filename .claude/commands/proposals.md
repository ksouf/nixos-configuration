# Command: /proposals

View and manage improvement proposals.

## Process

### Step 1: Load Proposals
```bash
PROPOSALS="/etc/nixos/.claude/memory/proposals.jsonl"

echo "=== IMPROVEMENT PROPOSALS ==="
echo ""

echo "PENDING:"
grep '"status":"proposed"' "$PROPOSALS" 2>/dev/null | \
  while read line; do
    id=$(echo "$line" | grep -oh '"id":"[^"]*"' | cut -d'"' -f4)
    gap=$(echo "$line" | grep -oh '"gap":"[^"]*"' | cut -d'"' -f4)
    priority=$(echo "$line" | grep -oh '"priority":"[^"]*"' | cut -d'"' -f4)
    echo "  [$priority] $id: $gap"
  done

echo ""
echo "RECENTLY COMPLETED:"
grep '"status":"completed"' "$PROPOSALS" 2>/dev/null | tail -5 | \
  while read line; do
    id=$(echo "$line" | grep -oh '"id":"[^"]*"' | cut -d'"' -f4)
    gap=$(echo "$line" | grep -oh '"gap":"[^"]*"' | cut -d'"' -f4)
    echo "  $id: $gap"
  done

echo ""
echo "REJECTED:"
grep '"status":"rejected"' "$PROPOSALS" 2>/dev/null | tail -3 | \
  while read line; do
    id=$(echo "$line" | grep -oh '"id":"[^"]*"' | cut -d'"' -f4)
    gap=$(echo "$line" | grep -oh '"gap":"[^"]*"' | cut -d'"' -f4)
    echo "  $id: $gap"
  done
```

### Step 2: Priority Summary
```bash
echo ""
echo "SUMMARY:"
HIGH=$(grep '"status":"proposed"' "$PROPOSALS" 2>/dev/null | grep -c '"priority":"high"')
MED=$(grep '"status":"proposed"' "$PROPOSALS" 2>/dev/null | grep -c '"priority":"medium"')
LOW=$(grep '"status":"proposed"' "$PROPOSALS" 2>/dev/null | grep -c '"priority":"low"')
echo "  High priority: $HIGH"
echo "  Medium priority: $MED"
echo "  Low priority: $LOW"
```

## Proposal Format
```json
{
  "id": "prop_[timestamp]",
  "ts": "[ISO8601]",
  "type": "skill|agent|hook|rule",
  "gap": "[description of what's missing]",
  "proposal": "[solution]",
  "priority": "high|medium|low",
  "effort": "trivial|small|medium|large",
  "status": "proposed|implementing|completed|rejected",
  "evidence": ["interaction_ids"],
  "implemented_at": null
}
```

## Actions

### Implement a Proposal
1. Read the proposal details
2. Create the skill/agent/hook/rule
3. Update proposal status:
   ```json
   {"status": "completed", "implemented_at": "[ISO8601]"}
   ```
4. Log to evolution.jsonl
5. Commit changes

### Reject a Proposal
1. Update status to "rejected"
2. Add reason field
3. Log decision

## Output
```
PROPOSALS DASHBOARD
===================
Pending: [N] (high: [H], medium: [M], low: [L])
Completed: [N]
Rejected: [N]

Next Actions:
  1. [high priority proposal]
  2. [high priority proposal]
```

## Invocation
User says: "proposals", "/proposals", "show proposals", "pending improvements"
