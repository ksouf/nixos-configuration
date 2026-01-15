# Command: /improve

Cycle 2 - Run 18-rule improvement engine. Analyze, fix gaps, commit.

## Process

### Step 1: Load Rules
Read `.claude/rules/improvement-rules.md`

### Step 2: Check Each Rule Category

**Skills (S1-S5):**
- [ ] S1: Did relevant skills trigger?
- [ ] S2: Did skills cover everything needed?
- [ ] S3: Any false skill triggers?
- [ ] S4: Task done 3x without skill?
- [ ] S5: Any outdated skill content?

**Agents (A1-A5):**
- [ ] A1: Should an agent have been used?
- [ ] A2: Was agent output helpful?
- [ ] A3: Need new specialist agent?
- [ ] A4: Agent had right capabilities?
- [ ] A5: Agent stayed on mission?

**Hooks (H1-H4):**
- [ ] H1: Manual step to automate?
- [ ] H2: Any hook failures?
- [ ] H3: Slow hooks to optimize?
- [ ] H4: Missing lifecycle hooks?

**Rules (R1-R5):**
- [ ] R1: Undocumented practice learned?
- [ ] R2: Was any rule violated?
- [ ] R3: Any rule conflicts?
- [ ] R4: Outdated rules?
- [ ] R5: Missing critical rule?

**Knowledge (K1-K3):**
- [ ] K1: New knowledge to capture?
- [ ] K2: Pattern repeated 3+ times?
- [ ] K3: Recurring error to prevent?

### Step 3: Apply Improvements
For each triggered rule, take the specified action:
- Update skill content
- Improve agent instructions
- Add/fix hooks
- Update rules or CLAUDE.md
- Add to knowledge base

### Step 4: Log Improvements
Append to `.claude/memory/improvements.jsonl`:
```json
{
  "ts": "[ISO8601]",
  "task": "[description]",
  "rules_triggered": ["S2", "K1"],
  "actions": [
    {"rule": "S2", "action": "Added wireplumber to audio skill"},
    {"rule": "K1", "action": "Documented PipeWire gotcha"}
  ]
}
```

### Step 5: Commit (if improvements made)
```bash
git -C /etc/nixos add .claude/ CLAUDE.md
git -C /etc/nixos commit -m "improve(auto): [rules triggered]

- [improvement 1]
- [improvement 2]

Self-improvement commit"
```

## Output
```
CYCLE 2 RESULTS
===============
Rules checked: 18
Rules triggered: [count]
Improvements made: [count]
Files changed: [list]

System is now smarter.
```

## Invocation
User says: "improve", "/improve", "run improvement cycle"
