# APLakeside — Agent Instructions

## Multi-agent setup
This project uses Claude Code + Codex as a two-agent system.

- `tools/orchestrate.ps1 -Task "..."` — master orchestrator: plans, runs both agents in parallel, synthesises
- `tools/ask-codex.ps1 -Prompt "..."` — consult Codex on a specific question
- `tools/ask-claude.ps1 -Prompt "..."` — Codex uses this to consult Claude

## Shared vault
Session logs and inter-agent notes live in the sibling repo `My-friends/`:
- `My-friends/log/sessions.md` — auto-logged after each orchestrator run
- `My-friends/claude/` — notes I leave for Codex
- `My-friends/codex/` — notes Codex leaves for me

## Rules
- Never delegate back to the agent that called you (no recursive loops)
- Production deployments require Will's explicit approval
- Use branches for parallel work on the same files
