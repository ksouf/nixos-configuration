# Command: /complete

Run ALL iteration cycles - the proper way to complete any task.

## Mandatory Cycles

### Cycle 1: Validation (/iterate)
```
1. Syntax check all modified .nix files
2. Run nix flake check
3. Run nixos-rebuild build
```
**Must pass before Cycle 2.**

### Cycle 2: Self-Improvement (/improve)
```
1. Check all 18 rules (S1-S5, A1-A5, H1-H4, R1-R5, K1-K3)
2. Apply improvements for triggered rules
3. Log and commit changes
```

### Cycle 3: Meta-Improvement (/meta)
Run if:
- 5+ tasks since last meta-cycle
- Explicitly requested
- Improvement rate declining
```
1. Analyze rule effectiveness
2. Detect automation gaps
3. Generate/implement proposals
```

## Process

### Execute All Cycles
```bash
echo "COMPLETE TASK WORKFLOW"
echo "======================"

# Cycle 1
echo ""
echo "CYCLE 1: VALIDATION"
echo "-------------------"
# Run /iterate steps

# Cycle 2
echo ""
echo "CYCLE 2: SELF-IMPROVEMENT"
echo "-------------------------"
# Run /improve steps

# Cycle 3 (conditional)
TASKS_SINCE_META=$(...)
if [ "$TASKS_SINCE_META" -ge 5 ]; then
  echo ""
  echo "CYCLE 3: META-IMPROVEMENT"
  echo "-------------------------"
  # Run /meta steps
fi
```

## Definition of Done
- [ ] Cycle 1: Build passes
- [ ] Cycle 2: Rules checked, improvements committed
- [ ] Cycle 3: Meta-analysis done (if due)

## Only After All Cycles
Task can be marked COMPLETE.

## Output
```
TASK COMPLETION SUMMARY
=======================
Cycle 1 (Validation): PASSED
Cycle 2 (Improvement): [N] rules triggered, [M] improvements
Cycle 3 (Meta): [Completed/Skipped]

Task Status: COMPLETE
System is now smarter.
```

## Invocation
User says: "complete", "/complete", "finish task", "done"
