---
name: init-agents-md
description: Use when a project has a CLAUDE.md (or GEMINI.md) and you want to create a universal AGENTS.md as the single source of truth for all AI agents. Also triggers on "create AGENTS.md", "universal agent config", "make instructions work for all agents", or "CLAUDE.md to AGENTS.md".
---

# Init AGENTS.md

## Overview

Consolidate all agent config files (`CLAUDE.md`, `GEMINI.md`, etc.) into a single `AGENTS.md` — the universal format read by Claude Code, Gemini CLI, OpenAI Codex, and other AI agents. Then slim each platform file down to a one-line pointer so `AGENTS.md` is the single source of truth.

## Why AGENTS.md

- `CLAUDE.md` is Claude Code-only
- `GEMINI.md` is Gemini CLI-only
- `AGENTS.md` is read by all major AI agent platforms (Claude, Gemini, Codex, etc.)
- One file to update instead of keeping multiple in sync

## Process

### 1. Audit existing config files

Read all agent config files that exist:
- `CLAUDE.md`
- `GEMINI.md`
- `AGENTS.md` (if already exists — offer to update rather than recreate)
- `.claude/` directory for any project-level settings

Note any platform-specific instructions (Claude Code hooks, Gemini-specific syntax) — these stay in their platform file, everything else moves to `AGENTS.md`.

### 2. Write AGENTS.md

Consolidate content into `AGENTS.md`. Keep the same sections and information but:

- Use agent-agnostic language — remove Claude-specific phrasing ("Claude Code", "Claude will", etc.)
- Replace with neutral phrasing ("The agent should...", "Run X to...", "Avoid...")
- Preserve all technical content: commands, architecture, conventions, key files, integrations
- Add a brief preamble explaining the file's purpose:

```markdown
# AGENTS.md

> Universal agent instructions for this project. Read by Claude Code, Gemini CLI, Codex, and other AI agents.
> Platform-specific config files (CLAUDE.md, GEMINI.md) defer to this file.
```

**Sections to include** (mirror what exists in source files, always include if relevant):

| Section | Content |
|---|---|
| Commands | Dev, test, lint, build commands |
| Architecture | Stack, key directories, patterns |
| Conventions | Code style, naming, file organization |
| Key files | Important files agents should know about |
| External integrations | APIs, services, config locations |
| Do / Don't | Explicit rules for agent behavior |
| Context files | Pointers to docs like `docs/product-marketing.md` |

### 3. Slim down platform files

**For each platform file that existed** (`CLAUDE.md`, `GEMINI.md`):

Replace the entire content with a stub that:
1. Points to `AGENTS.md` as the source of truth
2. Contains ONLY genuinely platform-specific instructions (hooks, platform syntax, etc.)
3. Is otherwise empty

Minimal stub template:
```markdown
# CLAUDE.md

See [AGENTS.md](./AGENTS.md) for all project instructions.

## Claude Code-specific notes
[Only add this section if there are actual Claude Code-specific things — hooks, MCP config, etc. Otherwise omit entirely.]
```

**If there is nothing platform-specific to keep: the stub is just the two-line pointer. Do not pad it.**

### 4. Verify

- Re-read `AGENTS.md` and confirm all meaningful content from the source files made it across
- Re-read the stubbed platform files and confirm they're minimal and point correctly
- Check that no content was lost or duplicated

### 5. Report

Tell the user:
- What was consolidated into `AGENTS.md`
- What (if anything) was kept in each platform file and why
- Any sections that needed interpretation or judgment calls

## Common Mistakes

| Mistake | Fix |
|---|---|
| Leaving `CLAUDE.md` with full content AND creating `AGENTS.md` | Slim `CLAUDE.md` down — two sources of truth defeats the purpose |
| Copying Claude-specific phrasing into `AGENTS.md` | Rewrite as agent-agnostic instructions |
| Putting platform-specific hooks/config into `AGENTS.md` | Keep those in the platform file stub |
| Creating `AGENTS.md` but not updating `CLAUDE.md` | Always update all platform files to point to `AGENTS.md` |
| Losing content during consolidation | Re-read both files after writing to verify |
