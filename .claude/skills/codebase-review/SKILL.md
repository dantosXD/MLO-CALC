---
name: codebase-review
description: Run a comprehensive, multi-perspective review of the MLO-CALC codebase using specialized parallel subagents. Use when the user asks to "review the codebase", "audit the code", "run a full code review", "check code quality", or "what's wrong with the code". Dispatches 7 specialized subagents in parallel — architecture, security, test coverage, performance, code quality, Flutter framework, and Dart language — then consolidates findings into a prioritized action report.
---

# Codebase Review

Dispatch all 7 reviewer subagents **in parallel** (single Agent tool message with 7 blocks), then consolidate.

## Subagents to Dispatch

See `references/reviewer-prompts.md` for the full prompt for each reviewer. Pass each prompt verbatim to a `general-purpose` subagent.

| Subagent | Focus |
|----------|-------|
| `architecture-reviewer` | Layer boundaries, DI (get_it), Provider patterns, feature module isolation |
| `security-reviewer` | flutter_secure_storage usage, API key handling, Gemini credential flows |
| `test-coverage-reviewer` | Unit/widget/golden test gaps, missing edge cases, flaky golden tests |
| `performance-reviewer` | Widget rebuild storms, async anti-patterns, SQLite query efficiency |
| `code-quality-reviewer` | Lint violations, dead code, Dart best practices, consistency |
| `flutter-reviewer` | Widget composition, BuildContext safety, Keys, animations, theming, responsive layout |
| `dart-reviewer` | Null safety, immutability, async correctness, financial precision (double vs Decimal), Dart 3 patterns |

## Dispatch Instructions

1. Read `references/reviewer-prompts.md` to get the full prompt for each subagent.
2. Launch all 7 agents simultaneously in one message using the Agent tool.
3. Each agent should use `subagent_type: general-purpose` and perform **read-only** analysis.
4. Wait for all 7 to return.

## Consolidation

After all agents return, produce a single **Codebase Review Report** structured as:

```
## Codebase Review Report

### Critical Issues  (block merges, data loss risk)
### High Priority   (architectural debt, security gaps)
### Medium Priority (test coverage, performance)
### Low Priority    (style, minor improvements)

### Summary Table
| Area | Grade | Top Finding |
|------|-------|-------------|
| Architecture | A-F | ... |
| Security | A-F | ... |
| Test Coverage | A-F | ... |
| Performance | A-F | ... |
| Code Quality | A-F | ... |
| Flutter | A-F | ... |
| Dart | A-F | ... |

### Recommended Next Steps (top 3 action items)
```

Only include sections that have findings. Skip empty sections.
