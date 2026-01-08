# Command: /status

Display the current status of the self-improving system.

## What to Show

1. **Memory Stats**
   - Total issues detected
   - Issues resolved vs pending
   - Patterns learned
   - Rules generated

2. **Recent Activity**
   - Last 5 issues from `.claude/memory/issues.jsonl`
   - Last 5 fixes from `.claude/memory/fixes.jsonl`

3. **Rules Overview**
   - Count of built-in rules
   - Count of learned rules
   - Highest/lowest confidence rules

4. **Evolution Metrics**
   - Evolution cycles completed
   - Success rate of fixes

## Output Format

```
Self-Improving System Status
============================

Memory:
  Issues: [resolved]/[total] resolved
  Patterns: [count] learned
  Rules: [built-in] + [learned] generated

Recent Issues:
  - [severity] [type]: [description] ([resolved/pending])
  ...

Rules:
  Built-in: [list]
  Learned: [list]
  Avg Confidence: [score]

Last Evolution: [timestamp]
```

## Invocation

User says: "status" or "show system status" or "/status"
