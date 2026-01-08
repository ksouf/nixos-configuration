# Command: /evolve

Trigger an evolution cycle of the self-improving system.

## Process

1. **Read Memory**
   - Load all issues, fixes, patterns from memory
   - Identify unprocessed entries (no evolution_processed flag)

2. **Analyze Patterns**
   - Group issues by type and similarity
   - Calculate occurrence frequencies
   - Identify candidates for rule generation

3. **Generate Rules**
   - For patterns with 4+ occurrences, generate a rule
   - Create rule file in `.claude/rules/learned/`
   - Set initial confidence based on occurrence ratio

4. **Update Confidence**
   - For existing rules, check fix success rate
   - Increase confidence for successful fixes
   - Decrease confidence for failed fixes
   - Archive rules with confidence < 0.3

5. **Record Metrics**
   - Update `.claude/memory/metrics.jsonl`
   - Increment evolution_cycles counter

## Output Format

```
Evolution Cycle Complete
========================

Analyzed: [count] issues, [count] fixes

Pattern Detection:
  - [pattern]: [count] occurrences -> [action]
  ...

Rules Updated:
  - [rule]: confidence [old] -> [new]
  ...

Rules Generated:
  - [new-rule.md]: [description]
  ...

Next Evolution: [recommended timing]
```

## Invocation

User says: "evolve" or "run evolution" or "/evolve"
