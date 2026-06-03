# Qwen3.6 Agentic Development Profile

## Why this profile exists

`prompts/profiles/qwen3_6_agentic_development.j2` is a local OpenHands prompt profile for agentic coding with a Qwen3.6-35B-A3B style model behind a local OpenAI-compatible endpoint.

The profile is intentionally narrow. It is meant to improve long-running coding behavior, context discipline, validation reporting, and practical autonomy while preserving the safety and workflow intent of the copied upstream OpenHands prompts.

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

It also does not flatten the upstream Jinja prompt tree. The copied `system_prompt.j2` remains the composition root for upstream includes such as `self_documentation.j2`, `security_policy.j2`, `security_risk_assessment.j2`, and `model_specific/*`.

## Recommended use

Use this profile for normal local coding when the agent should inspect first, make a bounded project-scoped change, validate it, and provide a compact final report.

Use it for long multi-step debugging when you want stronger phase discipline, evidence-first troubleshooting, and fewer stalls, without forcing large context dumps or broad speculative edits.

Use it with OpenHands running against a local Qwen3.6-35B-A3B style model through an OpenAI-compatible endpoint when reliability, compactness, and stable reasoning matter more than verbose explanation.

## Combining with `system_prompt.j2`

This profile is intended to be layered with the copied upstream `system_prompt.j2`, not used as a replacement for it.

A future assembly step can render the normal upstream OpenHands system prompt first, then append `prompts/profiles/qwen3_6_agentic_development.j2` afterward as additional local operating guidance. That keeps upstream safety, security, model-specific, and self-documentation includes intact while adding the local Qwen3.6 agentic-development behavior.

No upstream prompt file has to be patched to use this file in a generated prompt output later.
