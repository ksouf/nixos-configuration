# Command: /report

Generate session improvement report showing what the system learned.

## Process

### Step 1: Session Activity
```bash
MEMORY="/etc/nixos/.claude/memory"
TODAY=$(date +%Y-%m-%d)

echo "SESSION IMPROVEMENT REPORT"
echo "=========================="
echo "Date: $TODAY"
echo ""

# Today's activity
echo "TODAY'S ACTIVITY"
TASKS_TODAY=$(grep "$TODAY" "$MEMORY/interactions.jsonl" 2>/dev/null | wc -l)
AUTO_TODAY=$(grep "$TODAY" "$MEMORY/interactions.jsonl" 2>/dev/null | grep -c '"manual":false')
echo "  Tasks completed: $TASKS_TODAY"
echo "  Automated: $AUTO_TODAY"
```

### Step 2: Triggers Activated
```bash
echo ""
echo "TRIGGERS ACTIVATED"
SKILLS=$(grep "$TODAY" "$MEMORY/interactions.jsonl" 2>/dev/null | \
  grep -oh '"skills":\[[^\]]*\]' | grep -oh '"[^"]*"' | sort -u | tr '\n' ' ')
echo "  Skills: ${SKILLS:-none}"

RULES=$(grep "$TODAY" "$MEMORY/improvements.jsonl" 2>/dev/null | \
  grep -oh '"[A-Z][0-9]*"' | sort -u | tr '\n' ' ')
echo "  Rules: ${RULES:-none}"
```

### Step 3: Improvements Made
```bash
echo ""
echo "IMPROVEMENTS MADE"
IMP_TODAY=$(grep "$TODAY" "$MEMORY/improvements.jsonl" 2>/dev/null | wc -l)
echo "  Count: $IMP_TODAY"

if [ "$IMP_TODAY" -gt 0 ]; then
  echo "  Details:"
  grep "$TODAY" "$MEMORY/improvements.jsonl" 2>/dev/null | \
    grep -oh '"action":"[^"]*"' | sed 's/"action":"/    - /; s/"$//' | head -5
fi
```

### Step 4: Gaps Identified
```bash
echo ""
echo "GAPS IDENTIFIED"
grep "$TODAY" "$MEMORY/proposals.jsonl" 2>/dev/null | \
  grep -oh '"gap":"[^"]*"' | head -3 | sed 's/"gap":"/  - /; s/"$//'
```

### Step 5: Knowledge Gained
```bash
echo ""
echo "KNOWLEDGE GAINED"
# Check for new knowledge files
find /etc/nixos/.claude/knowledge -name "*.md" -mtime 0 2>/dev/null | \
  while read f; do echo "  - $(basename $f)"; done
```

### Step 6: Next Session Focus
```bash
echo ""
echo "NEXT SESSION FOCUS"
grep '"status":"proposed"' "$MEMORY/proposals.jsonl" 2>/dev/null | \
  grep '"priority":"high"' | head -2 | \
  grep -oh '"gap":"[^"]*"' | sed 's/"gap":"/  - /; s/"$//'
```

## Output
```
SESSION IMPROVEMENT REPORT
==========================
Date: [YYYY-MM-DD]

TODAY'S ACTIVITY
  Tasks: [N]
  Automated: [N]

TRIGGERS ACTIVATED
  Skills: [list]
  Rules: [list]

IMPROVEMENTS MADE
  Count: [N]
  - [improvement 1]
  - [improvement 2]

GAPS IDENTIFIED
  - [gap 1]
  - [gap 2]

KNOWLEDGE GAINED
  - [new file]

NEXT SESSION FOCUS
  - [high priority item]
  - [high priority item]

==========================
System grew smarter today.
```

## Invocation
User says: "report", "/report", "session report", "what did we learn"
