# NixOS Self-Improvement Engine - 18 Rules

Check EVERY rule after EVERY task. When triggered, take action AND log it.

---

## SKILL RULES (S1-S5)

### S1: Missing Trigger
- **If:** Skill should have triggered but didn't
- **Detection:** Task involved NixOS pattern but skill instructions weren't followed
- **Action:** Add missing keywords to skill description
- **NixOS Examples:** "module", "service", "package", "flake", "overlay"

### S2: Incomplete Coverage
- **If:** Skill triggered but missed important aspects
- **Detection:** Made mistakes the skill should have prevented
- **Action:** Add missing content to skill
- **NixOS Examples:** Missed deprecation, forgot lib.mkIf, wrong option path

### S3: Overly Broad
- **If:** Skill triggers too often
- **Detection:** Skill activates on unrelated tasks
- **Action:** Make description more specific
- **NixOS Examples:** Hardware skill triggering on all module work

### S4: Missing Skill
- **If:** Task type repeated 3+ times without skill
- **Detection:** Same guidance given manually multiple times
- **Action:** Create new skill
- **NixOS Examples:** Home Manager configs, secret management, flake inputs

### S5: Outdated Content
- **If:** Skill references deprecated NixOS patterns
- **Detection:** Skill suggests removed options or old syntax
- **Action:** Update skill content
- **NixOS Examples:** Old xserver options, removed packages, changed paths

---

## AGENT RULES (A1-A5)

### A1: Underutilized
- **If:** Agent not used when it should be
- **Detection:** Task matched agent's domain but wasn't invoked
- **Action:** Add "MUST USE" prominence to agent
- **NixOS Examples:** Auditor not used before rebuild, validator skipped

### A2: Unhelpful Output
- **If:** Agent output wasn't useful
- **Detection:** Output too generic or missed NixOS specifics
- **Action:** Improve agent instructions
- **NixOS Examples:** Generic advice instead of specific nix commands

### A3: Missing Agent
- **If:** Need for new specialist
- **Detection:** Repeated specialized task with no agent
- **Action:** Create new agent
- **NixOS Examples:** Flake update agent, security audit agent, migration agent

### A4: Wrong Capabilities
- **If:** Agent lacks needed tools/access
- **Detection:** Agent couldn't complete NixOS task
- **Action:** Adjust agent specification
- **NixOS Examples:** Agent needs Bash for nix commands, Read for configs

### A5: Mission Drift
- **If:** Agent not following core purpose
- **Detection:** Agent output drifted from NixOS focus
- **Action:** Reinforce core instructions

---

## HOOK RULES (H1-H4)

### H1: Missing Automation
- **If:** Manual step should be automated
- **Detection:** Same validation done manually each time
- **Action:** Add hook
- **NixOS Examples:** Syntax check after edit, flake check before commit

### H2: Hook Failure
- **If:** Hook exists but fails
- **Detection:** Script errors or blocks valid operations
- **Action:** Fix hook script
- **NixOS Examples:** nix-instantiate failing on valid syntax

### H3: Performance Issue
- **If:** Hook is too slow
- **Detection:** Noticeable delay in workflow
- **Action:** Optimize hook
- **NixOS Examples:** Full flake check on every edit (too slow)

### H4: Missing Event
- **If:** Important NixOS event not hooked
- **Detection:** Need automation at lifecycle point
- **Action:** Add hook
- **NixOS Examples:** Pre-rebuild validation, post-switch verification

---

## RULE RULES (R1-R5)

### R1: Undocumented Practice
- **If:** Good NixOS practice not documented
- **Detection:** Learned something useful during task
- **Action:** Add to knowledge base
- **NixOS Examples:** New module pattern, useful lib function, flake trick

### R2: Violated Rule
- **If:** Documented rule was broken
- **Detection:** CLAUDE.md rule ignored
- **Action:** Make rule more prominent
- **NixOS Examples:** Forgot to check syntax, modified hardware-configuration.nix

### R3: Conflicting Rules
- **If:** Rules contradict
- **Detection:** Two rules give conflicting guidance
- **Action:** Resolve conflict
- **NixOS Examples:** "Always use mkIf" vs "Keep simple modules flat"

### R4: Outdated Rule
- **If:** Rule references outdated NixOS practices
- **Detection:** Rule suggests deprecated approach
- **Action:** Update rule
- **NixOS Examples:** Rules about nix-env, channels, old options

### R5: Missing Critical Rule
- **If:** Critical NixOS standard not documented
- **Detection:** Important pattern not in CLAUDE.md
- **Action:** Add to critical section
- **NixOS Examples:** Security hardening, boot safety, service conflicts

---

## KNOWLEDGE RULES (K1-K3)

### K1: New Learning
- **If:** Gained NixOS knowledge during task
- **Detection:** Discovered something worth remembering
- **Action:** Document in knowledge base
- **NixOS Examples:** Quirky option behavior, package gotcha, flake pattern

### K2: Pattern Emergence
- **If:** Pattern repeated 3+ times
- **Detection:** Same NixOS fix/approach used repeatedly
- **Action:** Create automation (skill/rule/hook)
- **NixOS Examples:** PipeWire migration, xkb update, user module pattern

### K3: Recurring Error
- **If:** Same NixOS error keeps happening
- **Detection:** Identical mistake made multiple times
- **Action:** Add prevention automation
- **NixOS Examples:** Missing lib import, wrong option type, circular imports

---

## Quick Reference Table

| Rule | Trigger | Action |
|------|---------|--------|
| S1 | Skill didn't trigger | Add keywords to skill |
| S2 | Skill missed aspects | Expand skill content |
| S3 | Skill triggers too much | Make description specific |
| S4 | Task done 3x without skill | Create new skill |
| S5 | Skill has outdated content | Update skill |
| A1 | Agent not used | Add prominence |
| A2 | Agent unhelpful | Improve instructions |
| A3 | Need new specialist | Create agent |
| A4 | Agent lacks capability | Adjust tools |
| A5 | Agent off-mission | Reinforce instructions |
| H1 | Manual step repeated | Add hook |
| H2 | Hook fails | Fix script |
| H3 | Hook too slow | Optimize |
| H4 | Event not hooked | Add hook |
| R1 | Undocumented practice | Add to knowledge |
| R2 | Rule violated | Make prominent |
| R3 | Rules conflict | Resolve |
| R4 | Outdated rule | Update |
| R5 | Missing critical rule | Add to CLAUDE.md |
| K1 | New learning | Document |
| K2 | Pattern repeated 3x | Automate |
| K3 | Recurring error | Add prevention |
