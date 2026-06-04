# LM Studio Qwen3.6 Template

`lmstudio/qwen3_6_openhands_chat_template.jinja` is the LM Studio Qwen3.6 chat template for the local OpenHands Qwen profile. It is not the OpenHands system prompt.

Apply this file in LM Studio as a model Prompt Template override for the Qwen3.6 model used by OpenHands. LM Studio supports Jinja prompt templates and per-model prompt-template overrides.

The artifacts stay separate:

- The OpenHands system prompt is managed by `scripts/install_qwen36_agentic_prompt.sh`.
- OpenHands runtime settings are managed separately by the agent settings script.
- `AGENTS.md` remains in the target project repo, such as ThomsonLint.

This template defaults `enable_thinking=true` and `preserve_thinking=true`. `preserve_thinking` is useful for agentic multi-turn workflows because it keeps prior assistant thinking in context when the template renders conversation history.

OpenHands can try to pass `preserve_thinking` through `litellm_extra_body.chat_template_kwargs`, but putting the default in the LM Studio Jinja template is more reliable when template kwargs are not propagated.

Qwen coding sampling belongs in `~/.openhands/agent_settings.json`, not inside the template:

- `temperature=0.6`
- `top_p=0.95`
- `top_k=20`
- `min_p=0.0`
- `presence_penalty=0.0`
- `repetition_penalty=1.0`

## Smoke Test

After applying the template:

1. Open a new OpenHands session.
2. Ask it to use `task_tracker`.
3. Ask it to run one terminal inspection command.
4. Confirm tool calls keep valid arguments and do not appear as plain text or inside `<think>`.
