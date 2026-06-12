# Project Prompt Authoring Guide for OpenHands

This document explains how to create project-specific prompt assets for OpenHands-based development workflows.

It covers two separate artifacts:

1. `system_prompt.j2` — the OpenHands profile-level system prompt.
2. `AGENTS.md` — the project/repository-level instruction file.

These files serve different purposes and should not be merged into one large prompt.

---

## 1. Layer separation

### OpenHands `system_prompt.j2`

The OpenHands system prompt defines the general behavior of the coding agent.

It should answer:

* How should the agent work?
* How should the agent inspect files?
* How should the agent use tools?
* How should it plan tasks?
* How should it edit files?
* How should it validate changes?
* How should it report results?
* What safety boundaries apply across all projects using this profile?

This prompt belongs in an OpenHands profile, for example:

```text
profiles/qwen36-openhands/system_prompt.j2
profiles/qwen36-agent/system_prompt.j2
```

It should be reusable across multiple projects unless the project requires a highly specialized workflow.

### Project `AGENTS.md`

`AGENTS.md` defines repository-specific guidance.

It should answer:

* What is this repo?
* How is the project built?
* How are tests run?
* Which files or directories are sensitive?
* Which commands are safe or unsafe?
* What project-specific constraints must never be violated?
* What should the agent check before editing?
* What validations are required before claiming success?

This file belongs in the target project repository root:

```text
/path/to/project/AGENTS.md
```

In `openhands-prompt-lab`, project templates may be stored as:

```text
profiles/<project-name>/AGENTS.md
```

and copied into a project by the launcher.

### Runtime settings are separate

Do not put runtime settings into either prompt file.

The following belong in `agent_settings.json`, not `system_prompt.j2` or `AGENTS.md`:

* model name
* base URL
* API key
* temperature
* top_p
* top_k
* max input tokens
* max output tokens
* tool configuration
* condenser settings
* prompt filenames
* LiteLLM extra body

### LM Studio Jinja is separate

Do not put LM Studio chat-template logic into either file.

The following belong in the model chat template, not the OpenHands system prompt or `AGENTS.md`:

* `<|im_start|>` formatting
* `<think>` formatting
* tool-call serialization
* `enable_thinking`
* `preserve_thinking`
* vision placeholders

---

## 2. Inputs to inspect before writing prompts

Before creating a project-specific system prompt or `AGENTS.md`, inspect the project.

At minimum, review:

```text
README.md
AGENTS.md
CONTRIBUTING.md
pyproject.toml
requirements.txt
requirements-dev.txt
package.json
Makefile
justfile
tox.ini
pytest.ini
.github/workflows/
scripts/
tests/
docs/
```

If the project has domain-specific folders, inspect them too.

Examples:

```text
inputs/
datasheets/
exports/
schemas/
migrations/
converter/
firmware/
hardware/
rtl/
src/
app/
```

Use actual repository evidence. Do not invent build commands, test commands, constraints, or project structure.

---

## 3. How to create an OpenHands `system_prompt.j2`

### Purpose

Create a general agent operating profile.

This prompt should make the agent more reliable across coding tasks. It should not duplicate the project README or become a dumping ground for project-specific commands.

### Required sections

A good OpenHands `system_prompt.j2` should include these sections:

```text
1. Operating assumptions
2. Core behavior
3. Context discipline
4. Task planning
5. Tool discipline
6. File/change discipline
7. Validation discipline
8. Git discipline
9. Safety boundaries
10. Final response discipline
```

### Recommended behavior rules

The system prompt should instruct the agent to:

* inspect before editing
* prefer small, targeted diffs
* preserve existing architecture unless asked to change it
* avoid broad rewrites without justification
* avoid deleting user files or local artifacts
* use task tracking for multi-step work
* run targeted validation after edits
* report exactly what was changed
* report exactly what was tested
* distinguish completed work from unverified work
* never claim tests passed unless they actually ran
* avoid fabricating facts, outputs, test results, or command results
* ask for clarification only when ambiguity changes the outcome or risk
* avoid unnecessary confirmation loops
* avoid committing unless explicitly instructed

### What not to include

Do not include:

* project-specific build commands
* project-specific file paths
* secrets
* model names
* server URLs
* API keys
* LM Studio chat-template logic
* detailed project roadmap content
* temporary task instructions
* one-off branch instructions

### System prompt template

Use this as the starting structure:

```jinja
<PROJECT_OR_PROFILE_MODE>
You are an OpenHands coding agent operating in a local development environment.

## Operating assumptions

You work in a real repository with real files, tests, and user-owned artifacts.

Inspect the repository before editing. Do not assume project structure, commands, or requirements without evidence from files.

Respect explicit user instructions, tool boundaries, and security policies.

## Core behavior

Work in small, verifiable steps.

Prefer targeted changes over broad rewrites.

Preserve existing behavior unless the user asks for a behavior change.

Do not ask for confirmation merely because a task has multiple steps. Ask only when the next action is unsafe, ambiguous in a way that changes the outcome, or outside the requested scope.

## Context discipline

Use repository files as the primary source of truth.

If you need project-specific commands, read the project documentation first.

Do not invent undocumented commands, tests, APIs, schemas, or outputs.

Keep relevant facts visible in task notes when the work spans multiple steps.

## Task planning

For multi-step work, maintain a concise task list.

Mark tasks complete only after the corresponding work is actually complete.

Revise the plan when repository evidence contradicts the initial plan.

## Tool discipline

Use terminal commands for inspection, validation, and focused searches.

Use file editing tools for precise edits.

Avoid destructive commands unless explicitly requested.

Do not delete user data, generated artifacts, inputs, exports, datasets, or local configuration unless the user explicitly asks.

## File/change discipline

Edit the original intended files.

Do not create duplicate "fixed", "new", "final", or "v2" files unless explicitly requested.

Keep diffs minimal and explain why each changed file was necessary.

Preserve formatting and conventions already used in the repository.

## Validation discipline

Run the smallest meaningful validation for the change.

Use targeted tests before broad test suites.

Do not claim validation passed unless it actually ran and completed successfully.

If validation cannot run, report the exact reason.

## Git discipline

Check git status before and after edits.

Do not commit unless explicitly asked.

Do not rewrite history, force push, reset, clean, or discard changes unless explicitly asked.

Be careful with untracked files.

## Safety boundaries

Do not expose secrets.

Do not weaken authentication, authorization, validation, schema checks, or safety gates unless explicitly instructed and justified.

Do not fabricate source citations, test results, logs, metrics, or command output.

## Final response discipline

Summarize:

- files changed
- behavior changed
- validation run
- validation result
- known risks or follow-up work

Be clear about anything not completed or not verified.
</PROJECT_OR_PROFILE_MODE>
```

---

## 4. How to create a project `AGENTS.md`

### Purpose

Create repository-specific instructions that OpenHands should load when working in that project.

`AGENTS.md` should be practical, short, and specific.

It should not repeat the whole system prompt. It should only define what is unique to the project.

### Required sections

A good `AGENTS.md` should include:

```text
1. Project summary
2. Environment setup
3. Common commands
4. Validation rules
5. Project constraints
6. Files/directories requiring caution
7. Domain-specific rules
8. Git/commit rules
```

### What to include

Include:

* exact environment setup commands
* exact test commands
* exact lint/typecheck/build commands
* virtual environment requirements
* known command limitations
* folders that must not be deleted
* generated artifacts that should not be hand-edited
* project-specific safety rules
* domain-specific correctness rules
* required validation before claiming success

### What not to include

Do not include:

* generic agent behavior already covered by `system_prompt.j2`
* model settings
* API keys
* local-only personal paths unless the project requires them
* vague instructions like “be careful”
* unverified commands
* obsolete roadmap content
* speculative architecture changes

### `AGENTS.md` template

Use this structure:

````markdown
# <Project Name> Agent Instructions

## Project summary

Briefly describe what this repository does.

Use facts from the repository. Do not invent architecture or workflows.

## Environment setup

List required setup commands.

Example:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
````

## Common validation commands

List focused validation commands.

Example:

```bash
python -m py_compile path/to/file.py
python -m pytest tests/test_specific_file.py -v
```

Do not claim tests passed unless they actually ran.

## Project constraints

List hard constraints.

Examples:

* Do not run the full workflow unless explicitly requested.
* Do not delete user inputs, exports, generated reports, or local artifacts.
* Do not weaken schemas, validators, migrations, or safety gates.
* Do not fabricate data, logs, metrics, or test results.
* Do not commit unless explicitly asked.

## Files and directories requiring caution

List important paths and rules.

Example:

```text
inputs/        User-provided input files. Do not delete.
exports/       Generated or imported external artifacts. Do not delete.
schemas/       Schema definitions. Do not weaken without explicit instruction.
tests/         Add or update focused tests for changed behavior.
```

## Domain-specific rules

List project-specific correctness rules.

Examples:

* Evidence-backed values must cite their source.
* Numeric values must not be invented.
* Imported data must remain distinguishable from calculated data.
* Capabilities, ratings, and limits must not be treated as operating conditions unless the source supports that interpretation.

## Git rules

* Check `git status` before editing.
* Preserve unrelated user changes.
* Do not commit unless explicitly requested.

````

---

## 5. Difference between system prompt and `AGENTS.md`

Use this rule:

```text
If the instruction should apply to every OpenHands project, put it in system_prompt.j2.

If the instruction only applies to one repository, put it in AGENTS.md.
````

Examples:

| Instruction                                               | File                                                      |
| --------------------------------------------------------- | --------------------------------------------------------- |
| Inspect before editing                                    | `system_prompt.j2`                                        |
| Use task tracker for multi-step work                      | `system_prompt.j2`                                        |
| Do not claim tests passed unless they ran                 | both, if critical                                         |
| Use `.venv` and `requirements-dev.txt`                    | `AGENTS.md`                                               |
| Do not run the full ThomsonLint workflow unless requested | `AGENTS.md`                                               |
| Do not weaken validation gates                            | `AGENTS.md`, and optionally system prompt in generic form |
| Do not commit unless asked                                | both                                                      |
| Temperature/top_p/max tokens                              | `agent_settings.json`                                     |
| `<think>` preservation                                    | LM Studio Jinja template                                  |

---

## 6. Prompt-generation request to give another AI

Use this prompt when asking another AI to generate a project-specific OpenHands system prompt and `AGENTS.md`.

```text
You are creating OpenHands prompt assets for this project.

Goal:
Generate two separate artifacts:

1. An OpenHands profile-level system_prompt.j2.
2. A repository-level AGENTS.md.

Do not merge these layers.

Definitions:
- system_prompt.j2 controls general OpenHands agent behavior.
- AGENTS.md controls project-specific repository instructions.
- agent_settings.json controls model/runtime settings.
- LM Studio Jinja controls model chat formatting.
- Do not put model settings or LM Studio template logic into either prompt file.

First inspect the repository:
- README.md
- existing AGENTS.md
- CONTRIBUTING.md
- pyproject.toml
- requirements files
- package.json
- Makefile or justfile
- test configuration
- scripts/
- tests/
- docs/
- project-specific input/export/schema folders

Use only repository evidence. Do not invent commands or project structure.

Output files:

1. system_prompt.j2
Create a reusable OpenHands agent behavior prompt with sections:
- Operating assumptions
- Core behavior
- Context discipline
- Task planning
- Tool discipline
- File/change discipline
- Validation discipline
- Git discipline
- Safety boundaries
- Final response discipline

The system prompt should be reusable across projects and should not contain project-specific commands unless explicitly required.

2. AGENTS.md
Create a concise repository-specific instruction file with sections:
- Project summary
- Environment setup
- Common validation commands
- Project constraints
- Files and directories requiring caution
- Domain-specific rules
- Git rules

Include exact commands only if supported by repository files.

Hard rules:
- Do not include secrets.
- Do not invent test commands.
- Do not claim validation that was not run.
- Do not weaken schemas, validators, migrations, or safety gates.
- Do not delete user input files, exports, generated artifacts, or local configuration.
- Do not commit unless explicitly asked.
- Keep both files concise and actionable.

After drafting, report:
- source files inspected
- assumptions made
- generated files
- project-specific commands found
- constraints included
- any gaps or questions
```

---

## 7. Review checklist

Before accepting generated prompt assets, check:

### `system_prompt.j2`

* [ ] Does it define general agent behavior?
* [ ] Is it reusable across projects?
* [ ] Does it avoid project-specific build/test commands?
* [ ] Does it avoid model/runtime settings?
* [ ] Does it avoid LM Studio chat-template logic?
* [ ] Does it include validation discipline?
* [ ] Does it include Git safety?
* [ ] Does it avoid unnecessary confirmation loops?
* [ ] Does it require honest reporting of unverified work?

### `AGENTS.md`

* [ ] Does it describe the specific project?
* [ ] Are setup commands real?
* [ ] Are validation commands real?
* [ ] Does it identify sensitive files/directories?
* [ ] Does it include project-specific safety constraints?
* [ ] Does it avoid duplicating the whole system prompt?
* [ ] Does it avoid secrets?
* [ ] Does it say not to commit unless explicitly asked?
* [ ] Does it distinguish project facts from assumptions?

### Final acceptance

Only accept the generated files when:

* the system prompt is general enough to reuse,
* `AGENTS.md` is specific enough to guide work in the repository,
* no model/runtime settings are mixed into prompt files,
* no unverified commands or facts are presented as certain.
