# OpenHands Runtime Settings

This repo tracks sanitized prompt examples, profile docs, and install scripts. It should not track private OpenHands runtime state.

The main observed runtime settings file is `~/.openhands/agent_settings.json`. The current sanitized example is recorded in `config/openhands_agent_settings.example.json`.

`~/.openhands/cli_config.json` and `~/.openhands/mcp.json` are also relevant runtime config files. They can affect CLI behavior, MCP servers, and available tools, but private local copies should not be committed.

Do not commit these OpenHands runtime directories:

- `~/.openhands/conversations/`: session history.
- `~/.openhands/cache/skills/`: cached skills and plugin catalog data.

The prompt repo should keep sanitized examples and scripts only. It should not copy wholesale cache data, conversation history, raw settings, or real secrets from `~/.openhands`.

## Observed Qwen3.6 Alignment

The observed OpenHands settings use `openai/qwen3.6_35b_a3b_openhands` through a local OpenAI-compatible endpoint. The `api_key` and cloud credential fields are represented with placeholders in the example config.

The current settings confirm `task_tracker` is enabled, so the Qwen3.6 agentic profile's microtask tracking behavior can be used when OpenHands exposes that tool.

The current settings confirm `system_prompt_filename` is `system_prompt.j2`, so the one-shot installer patching `system_prompt.j2` is targeting the active prompt file.

`stream` is currently `false`. Changing streaming behavior is a runtime settings choice, not a prompt profile change.

`AGENTS.md` remains project-specific. It should live in the target project repo being worked on, such as ThomsonLint, not in the OpenHands install and not as an automatically generated file in this prompt repo.

## Artifact Boundaries

OpenHands runtime settings, the LM Studio chat template, and the OpenHands system prompt are separate artifacts:

- `~/.openhands/agent_settings.json` controls OpenHands runtime request and settings behavior.
- `lmstudio/qwen3_6_openhands_chat_template.jinja` controls model-side chat formatting in LM Studio.
- The OpenHands system prompt controls agent behavior and is managed by `scripts/install_qwen36_agentic_prompt.sh`.

See `docs/lmstudio_qwen36_template.md` for the LM Studio Qwen3.6 chat template notes.

## Applied Runtime Profile

`scripts/apply_openhands_agent_settings.sh` applies a Qwen3.6 coding-oriented runtime profile to `.llm` and, when already present, `.condenser.llm`.

The sampling defaults are tuned for local coding work with Qwen3.6:

- `temperature=0.6`
- `top_p=0.95`
- `top_k=20`
- `min_p=0.0`
- `presence_penalty=0.0`
- `repetition_penalty=1.0`

`max_output_tokens` defaults to `24000`. For ThomsonLint long-output runs, it can be raised to `30000`:

```bash
bash scripts/apply_openhands_agent_settings.sh --max-output-tokens 30000
```

`timeout` remains `null` because a request timeout is not the same as graceful interruption or continuation. Runtime timeout behavior should not be used as a substitute for resumable task handling.

`reasoning_effort` remains `"high"`. Values such as `"xhigh"` are provider/model-specific and should not be assumed for local Qwen3.6 through LM Studio.

## Qwen3.6 preserve_thinking

`preserve_thinking` is a Qwen3.6 chat-template and runtime setting, not a system prompt instruction. The prompt installer should not manage it.

OpenHands can pass this setting through the LiteLLM request body with `litellm_extra_body.chat_template_kwargs`:

```json
{
  "chat_template_kwargs": {
    "enable_thinking": true,
    "preserve_thinking": true
  }
}
```

`scripts/apply_openhands_agent_settings.sh` enables this by default for the Qwen3.6 agentic profile. To keep thinking mode enabled but disable thinking preservation, run:

```bash
bash scripts/apply_openhands_agent_settings.sh --no-preserve-thinking
```

LM Studio support depends on the loaded model preset, prompt template, and build. If LM Studio ignores `chat_template_kwargs`, set `preserve_thinking` in the LM Studio model prompt template or use a server that supports `chat_template_kwargs`, such as llama.cpp, vLLM, or SGLang.

Test preserve-thinking changes with tool-calling. Some Qwen3.6 plus thinking configurations can cause tool calls to appear in `reasoning_content` or plain text instead of structured `tool_calls`.
