# Rule Generator

This file guides Claude in generating new rules based on detected patterns.

## Rule Generation Process

1. **Detect**: Identify a recurring issue or pattern
2. **Abstract**: Extract the general form of the issue
3. **Validate**: Confirm the pattern appears multiple times
4. **Generate**: Create a rule to detect future occurrences
5. **Store**: Save to `.claude/rules/learned/`

## Rule Format

Rules are stored as markdown files with this structure:

```markdown
# Rule: [NAME]

## Trigger
[What triggers this rule - file pattern, content pattern, etc.]

## Detection
[How to detect the issue - regex, AST pattern, etc.]

## Fix
[How to fix the issue when detected]

## Confidence
[0.0-1.0 confidence score based on occurrences]

## Examples
[Real examples from this codebase]
```

## Learning Thresholds

- **New pattern**: Seen once, stored in memory
- **Emerging pattern**: Seen 2-3 times, flagged for review
- **Confirmed pattern**: Seen 4+ times, generate rule

## Auto-Generated Rules Location

Rules are stored in: `.claude/rules/learned/`

Format: `[issue-type]-[timestamp].md`
