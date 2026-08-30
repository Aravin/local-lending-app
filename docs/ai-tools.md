# AI Tools — Local Lending Hub

This document explains how AI tools are configured for this project.

## Antigravity IDE

**Rule file:** `.agents/rules/flutter.md`

Antigravity reads project rules from `.agents/rules/` automatically. The Flutter rule file enforces:
- Clean Architecture per feature
- `make gen` after freezed changes
- Test creation alongside every new file
- `flutter analyze` must pass before any commit

**AGENTS.md:** Root `AGENTS.md` gives the full project context to any AI tool.

To get Antigravity fully up to speed on a fresh context:
1. Say: *"Read AGENTS.md"*
2. Ask for what you need

## OpenCode

**Config:** `.opencode/AGENTS.md`

OpenCode reads from `.opencode/AGENTS.md` when invoked in this directory. Contains the same conventions as the root AGENTS.md but in a terminal-optimized format.

```bash
# Start OpenCode in the project
opencode
```

## Cursor

**Rule file:** `.cursor/rules`

Cursor reads `.cursor/rules` automatically for all files in this workspace.

## Best Practices for AI-Assisted Development

### Give Context, Not Just Tasks

Instead of: *"Add a loan application"*  
Prefer: *"Add a 4-step loan application form following the Clean Architecture pattern in lib/features/loans/. Check AGENTS.md for conventions."*

### Always Verify Generated Code

- Run `flutter analyze` after any AI-generated code
- Run `make test` to ensure tests still pass
- Check generated code doesn't bypass the layered architecture

### File Naming Hints

Tell the AI where to put files:
- Feature logic → `lib/features/<name>/domain/usecases/`
- BLoC → `lib/features/<name>/presentation/bloc/`
- Shared widget → `lib/shared/widgets/`

### EMI Calculation

Always remind the AI: *"EMI calculation must use `EmiCalculator` in `lib/core/utils/emi_calculator.dart` — never inline the math."*

### Testing Reminders

*"Create a corresponding test in `test/unit/` for this utility"*  
*"Create a widget test in `test/widget/` for this screen"*

## Context Files Summary

| File | Purpose | Read by |
|---|---|---|
| `AGENTS.md` | Full project context | Antigravity, OpenCode, Cursor, any AI |
| `.agents/rules/flutter.md` | Antigravity-specific rules | Antigravity IDE |
| `.opencode/AGENTS.md` | Terminal AI context | OpenCode |
| `.cursor/rules` | Cursor workspace rules | Cursor |
| `docs/architecture.md` | Architecture deep-dive | Human + AI reference |
| `docs/white-label.md` | How to add a client | Human + AI reference |
