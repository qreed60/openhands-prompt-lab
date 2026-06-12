# OpenHands Runtime Settings

This repo tracks declarative OpenHands profiles, sanitized prompt examples, profile docs, and bootstrap scripts. It should not track private OpenHands runtime state such as conversations, caches, credentials, or local-only config.

## Declarative Profiles

OpenHands runtime configuration for the launcher lives under `profiles/`.

- `profiles/qwen36-openhands/agent_settings.json`
- `profiles/qwen36-openhands/system_prompt.j2`
- `profiles/qwen36-openhands/security_policy.j2`
- `profiles/qwen36-agent/agent_settings.json`
- `profiles/qwen36-agent/system_prompt.j2`
- `profiles/qwen36-agent/security_policy.j2`

The launcher applies these files exactly as tracked in the repo. It does not generate settings procedurally, patch JSON fields, or patch the installed OpenHands SDK prompt tree at launch time.

Use `scripts/apply_openhands_profile.sh` to copy a selected profile into an OpenHands config directory:

```bash
bash scripts/apply_openhands_profile.sh --profile qwen36-openhands
```

The applier validates `agent_settings.json` as JSON, requires the prompt and security policy files to exist, backs up existing target files under `~/.openhands/backups/prompt-lab/<UTCSTAMP>/`, and then copies the repo profile files verbatim.

Dry-run mode reports the exact copy plan without modifying `~/.openhands`:

```bash
bash scripts/apply_openhands_profile.sh --dry-run --profile qwen36-openhands
```

## Launcher

`scripts/ohm` is the launcher entry point:

```bash
bash scripts/ohm --openhands-profile qwen36-openhands /path/to/project -- <openhands args>
```

By default it uses `qwen36-openhands` and the current directory as the project directory. In launch mode it first applies the selected OpenHands profile by calling `scripts/apply_openhands_profile.sh --profile NAME`, then launches `openhands`.

`--prepare-only` applies the selected OpenHands profile, handles optional `AGENTS.md` placement, and exits without launching OpenHands.

`--dry-run` passes dry-run mode through to the profile applier, reports optional `AGENTS.md` placement without copying or backing up project files, and exits without launching OpenHands. `--prepare-only` does not imply `--dry-run`.

## Model Overrides

The declarative profile supplies the normal model, endpoint, API key placeholder, prompts, tools, condenser, and runtime settings.

`scripts/ohm --model MODEL_OR_ALIAS` changes only `LLM_MODEL` for that single launch:

```bash
bash scripts/ohm --model agent /path/to/project
```

Supported aliases:

- `openhands`, `oh`: `openai/qwen3.6_35b_a3b_openhands`
- `agent`, `manager`: `openai/qwen3.6_35b_a3b_agent`
- `qwen2b`, `2b`: `openai/qwen35_2b`
- `kimi`, `vision`: `openai/kimi_vision`

The launcher does not set `LLM_BASE_URL`, `LLM_API_KEY`, or `OH_PERSISTENCE_DIR`. Those remain profile/local runtime concerns.

## Project AGENTS.md

`AGENTS.md` is project-specific. It belongs in the target project repository, not in the OpenHands SDK prompt tree.

Use `--project-profile NAME` to copy `profiles/NAME/AGENTS.md` into the selected project:

```bash
bash scripts/ohm --project-profile thomsonlint --prepare-only /mnt/projects/ThomsonLint
```

`--profile` remains an alias for `--openhands-profile`, and `--agents` remains an alias for `--project-profile`.

If `PROJECT_DIR/AGENTS.md` already exists, the launcher skips it and prints a message. Use `--force-agents` to back up the existing file and replace it.

## Legacy Bootstrap Scripts

The following scripts remain for manual/bootstrap use only:

- `scripts/apply_openhands_agent_settings.sh`
- `scripts/install_qwen36_agentic_prompt.sh`

They are intentionally not wired into `scripts/ohm`. The launcher uses declarative repo profiles instead of generating settings or patching the installed OpenHands SDK prompt tree.

## Runtime State Boundaries

The main local OpenHands runtime directory is `~/.openhands/`. Private local copies should not be committed.

Do not commit these OpenHands runtime paths:

- `~/.openhands/conversations/`: session history.
- `~/.openhands/cache/skills/`: cached skills and plugin catalog data.
- `~/.openhands/cli_config.json`: local CLI behavior.
- `~/.openhands/mcp.json`: local MCP configuration.

Runtime settings, the LM Studio chat template, and project instructions are separate artifacts:

- `~/.openhands/agent_settings.json` controls OpenHands runtime request and settings behavior.
- `lmstudio/qwen3_6_openhands_chat_template.jinja` controls model-side chat formatting in LM Studio.
- `profiles/*/system_prompt.j2` controls the OpenHands agent prompt copied by the profile applier.
- `profiles/*/security_policy.j2` controls the OpenHands security policy copied by the profile applier.
- `profiles/*/AGENTS.md` contains project-specific repo guidance copied only when requested.

See `docs/lmstudio_qwen36_template.md` for the LM Studio Qwen3.6 chat template notes.
