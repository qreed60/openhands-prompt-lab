# Qwen3.6 Agentic Development Profile

## Why this profile exists

`prompts/profiles/qwen3_6_agentic_development.j2` is a local OpenHands prompt profile for agentic coding with a Qwen3.6-35B-A3B style model behind a local OpenAI-compatible endpoint.

The profile is intended for generating the active OpenHands system prompt or a merged local system prompt. It is meant to improve long-running coding behavior, context discipline, validation reporting, and practical autonomy while preserving explicit user instructions, active tool constraints, and runtime security boundaries.

It also intentionally reduces unnecessary confirmation stalls for safe project-scoped work. The agent should keep moving when the next step directly supports the requested task and is safe to perform.

## Original prompt ideas reused

The profile reuses these ideas from the copied `system_prompt.j2`:

- OpenHands should inspect the codebase before editing.
- The agent should make focused, minimal code changes.
- Original files should be edited directly instead of creating duplicate fixed or test variants.
- Version-control operations should be cautious, with `git status` checked around changes.
- Non-interactive Git commands should use `git --no-pager` where needed.
- Browser and external-service use should be bounded and should prefer APIs or simpler tools when practical.
- Security boundaries matter: destructive, credential-related, upload, system-level, or broad scope changes require explicit consent.
- Validation should be real and should be reported accurately.

The profile reuses this idea from `system_prompt_long_horizon.j2`:

- Complex work benefits from visible task management and prompt status updates.

It adapts that idea so `task_tracker` is used when available, but the agent degrades gracefully to concise phase tracking if the tool is unavailable. It also avoids forcing task tracking for trivial tasks.

The profile reuses these ideas from `system_prompt_tech_philosophy.j2`:

- Prefer simplicity.
- Think about data structures and data flow before code shape.
- Avoid special cases when a cleaner structure can remove them.
- Preserve backward compatibility unless explicitly asked to break it.
- Solve real problems instead of theoretical ones.
- Reduce complexity and avoid unnecessary abstractions.

## Original prompt ideas intentionally not reused

The profile does not reuse the persona framing from the technical-philosophy prompt.

It does not mention the named persona from that prompt, does not copy abrasive language, and does not require rigid sections such as `Core Judgment`, `Taste Rating`, or a mandatory requirement-confirmation exchange before useful work begins.

It also does not flatten the upstream Jinja prompt tree. The copied `system_prompt.j2` can still supply upstream include content such as `self_documentation.j2`, `security_policy.j2`, `security_risk_assessment.j2`, and `model_specific/*` when a merged local system prompt is generated.

The profile should not cause the agent to look for additional limiting instructions before acting. The active generated prompt should be clear enough for safe local development, with explicit user instructions, tool constraints, and security boundaries still applying at runtime.

## Recommended use

Use this profile for normal local coding when the agent should inspect first, make a bounded project-scoped change, validate it, and provide a compact final report.

Use it for long multi-step debugging when you want stronger phase discipline, evidence-first troubleshooting, and fewer stalls, without forcing large context dumps or broad speculative edits.

Use it with OpenHands running against a local Qwen3.6-35B-A3B style model through an OpenAI-compatible endpoint when reliability, compactness, and stable reasoning matter more than verbose explanation.

## One-shot install

Install the profile into the local OpenHands prompt directory:

```bash
bash scripts/install_qwen36_agentic_prompt.sh
```

Dry run without modifying the installed OpenHands prompt directory:

```bash
bash scripts/install_qwen36_agentic_prompt.sh --dry-run
```

Force reinstall when the target already contains the Prompt Lab profile marker:

```bash
bash scripts/install_qwen36_agentic_prompt.sh --force
```

Restore from a backup path printed by the installer:

```bash
bash scripts/restore_openhands_prompt_backup.sh --backup-dir PATH_PRINTED_BY_INSTALLER
```

## Runtime settings alignment

The observed OpenHands config uses `openai/qwen3.6_35b_a3b_openhands` through the local OpenAI-compatible endpoint. It also enables `task_tracker`, sets `system_prompt_filename` to `system_prompt.j2`, keeps `tool_concurrency_limit` at `1`, and enables prompt caching.

`AGENTS.md` remains project-specific and should live in the target repo being worked on. It should not be installed into OpenHands or automatically generated into this prompt repo.

## LM Studio chat template

The Qwen3.6 OpenHands profile has a companion LM Studio Jinja chat template at `lmstudio/qwen3_6_openhands_chat_template.jinja`. It is separate from the OpenHands system prompt.

The LM Studio template controls message formatting, tool-call formatting, `enable_thinking`, and `preserve_thinking`. Install it manually into LM Studio until a safe LM Studio template installer is added.

## Generating a merged local prompt

This profile can be used to generate the active OpenHands system prompt or a merged local system prompt.

A future assembly step can render the copied OpenHands Jinja prompt content and merge `prompts/profiles/qwen3_6_agentic_development.j2` into that generated output. That keeps useful upstream safety, security, model-specific, and self-documentation content available while producing one active local Qwen3.6 agentic-development prompt.

No upstream prompt file has to be patched to use this file in a generated prompt output later.
