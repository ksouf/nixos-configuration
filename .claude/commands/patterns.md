# Command: /patterns

Show learned patterns and their status.

## What to Show

1. **Active Patterns**
   - Patterns that have generated rules
   - Occurrence count and confidence

2. **Emerging Patterns**
   - Patterns with 2-3 occurrences
   - Candidates for future rules

3. **New Patterns**
   - Single occurrence issues
   - Watching for recurrence

## Output Format

```
Learned Patterns
================

Active (rule generated):
  - [pattern-name]: [count] occurrences, [confidence] confidence
    Rule: .claude/rules/learned/[rule-file.md]
    Last seen: [timestamp]
  ...

Emerging (2-3 occurrences):
  - [pattern]: [count] occurrences
    Example: [description]
    Files: [list of affected files]
  ...

New (watching):
  - [pattern]: 1 occurrence
    [description]
  ...

Total Patterns: [count]
```

## Invocation

User says: "patterns" or "show patterns" or "/patterns"
