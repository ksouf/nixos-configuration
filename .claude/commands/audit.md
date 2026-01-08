# Command: /audit

Run a full audit of the NixOS configuration.

## Process

1. **Load Rules**
   - Read all rules from `.claude/rules/`
   - Include both built-in and learned rules

2. **Scan Files**
   - Find all `.nix` files in the repository
   - Skip `hardware-configuration.nix` (auto-generated)

3. **Apply Rules**
   - For each file, check against each rule
   - Record matches with file, line, and description

4. **Record Issues**
   - Append new issues to `.claude/memory/issues.jsonl`
   - Avoid duplicates (same file, line, rule)

5. **Generate Report**
   - Group by severity (critical, high, medium, low)
   - Include fix suggestions from rules

## Output Format

```
NixOS Configuration Audit
=========================

Scanned: [count] files
Rules applied: [count]

Critical ([count]):
  [file]:[line] - [description]
    Suggested fix: [fix from rule]
  ...

High ([count]):
  ...

Medium ([count]):
  ...

Low ([count]):
  ...

Summary:
  Total issues: [count]
  New issues: [count]
  Previously known: [count]
```

## Invocation

User says: "audit" or "run audit" or "/audit"
