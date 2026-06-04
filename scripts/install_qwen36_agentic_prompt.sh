#!/usr/bin/env bash
set -euo pipefail

DEFAULT_TARGET_DIR="/home/qreed/.local/share/uv/tools/openhands/lib/python3.12/site-packages/openhands/sdk/agent/prompts"
DEFAULT_PROFILE_PATH="prompts/profiles/qwen3_6_agentic_development.j2"
UPSTREAM_PATH="prompts/upstream/openhands_sdk_agent_prompts"
PATCHED_PATH="prompts/patched/openhands_sdk_agent_prompts"
PROFILE_MARKER="BEGIN OPENHANDS PROMPT LAB PROFILE"
PROFILE_MODE_MARKER="QWEN3_6_AGENTIC_DEVELOPMENT_MODE"

target_dir="${DEFAULT_TARGET_DIR}"
profile_path="${DEFAULT_PROFILE_PATH}"
dry_run=0
force=0
backup_path=""

usage() {
  cat <<'EOF'
Usage: bash scripts/install_qwen36_agentic_prompt.sh [options]

Options:
  --target-dir PATH  OpenHands prompt directory to patch.
  --profile PATH     Prompt Lab profile to inject.
  --dry-run          Validate and build patched tree without installing.
  --no-install       Alias for --dry-run.
  --force            Permit reinstalling over an already-profiled target.
  -h, --help         Show this help.
EOF
}

fail() {
  printf 'Install failure: %s\n' "$*" >&2
  if [[ -n "${backup_path}" ]]; then
    printf 'Backup path: %s\n' "${backup_path}" >&2
    printf 'Restore command: bash scripts/restore_openhands_prompt_backup.sh --backup-dir %q --target-dir %q\n' "${backup_path}" "${target_dir}" >&2
  fi
  exit 1
}

on_error() {
  local line_no="$1"
  if [[ -n "${backup_path}" ]]; then
    printf 'Install failure: command failed near line %s\n' "${line_no}" >&2
    printf 'Backup path: %s\n' "${backup_path}" >&2
    printf 'Restore command: bash scripts/restore_openhands_prompt_backup.sh --backup-dir %q --target-dir %q\n' "${backup_path}" "${target_dir}" >&2
  fi
}
trap 'on_error "$LINENO"' ERR

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir)
      [[ $# -ge 2 ]] || fail "--target-dir requires a path"
      target_dir="$2"
      shift 2
      ;;
    --profile)
      [[ $# -ge 2 ]] || fail "--profile requires a path"
      profile_path="$2"
      shift 2
      ;;
    --dry-run|--no-install)
      dry_run=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

copy_tree_replace() {
  local src="$1"
  local dest="$2"

  [[ -d "${src}" ]] || fail "source directory is missing: ${src}"
  mkdir -p "$(dirname "${dest}")"

  if command -v rsync >/dev/null 2>&1; then
    mkdir -p "${dest}"
    rsync -a --delete "${src}/" "${dest}/"
  else
    rm -rf "${dest}"
    cp -a "${src}" "${dest}"
  fi
}

copy_tree_over_target() {
  local src="$1"
  local dest="$2"

  [[ -d "${src}" ]] || fail "source directory is missing: ${src}"
  [[ -d "${dest}" ]] || fail "target directory is missing: ${dest}"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${src}/" "${dest}/"
  else
    cp -a "${src}/." "${dest}/"
  fi
}

[[ -d ".git" ]] || fail "run this script from the repository root"
[[ -d "prompts" ]] || fail "run this script from the repository root"
[[ -f "${DEFAULT_PROFILE_PATH}" ]] || fail "expected repo profile is missing: ${DEFAULT_PROFILE_PATH}"
[[ -f "${profile_path}" ]] || fail "profile is missing: ${profile_path}"
[[ -d "${target_dir}" ]] || fail "target prompt directory is missing: ${target_dir}"
[[ -f "${target_dir}/system_prompt.j2" ]] || fail "target system_prompt.j2 is missing: ${target_dir}/system_prompt.j2"

if grep -q "${PROFILE_MARKER}" "${target_dir}/system_prompt.j2" && [[ "${force}" -ne 1 ]]; then
  fail "target already contains the Prompt Lab profile marker; rerun with --force to reinstall"
fi

copy_tree_replace "${target_dir}" "${UPSTREAM_PATH}"
copy_tree_replace "${UPSTREAM_PATH}" "${PATCHED_PATH}"

python3 - "${PATCHED_PATH}/system_prompt.j2" "${profile_path}" "${PROFILE_MARKER}" <<'PY'
import pathlib
import re
import sys

system_path = pathlib.Path(sys.argv[1])
profile_path = pathlib.Path(sys.argv[2])
profile_marker = sys.argv[3]
insert_marker = "{%- set _imp -%}"

text = system_path.read_text()
profile = profile_path.read_text().rstrip()
profile_name = profile_path.name

block_pattern = re.compile(
    r"\n?\{# BEGIN OPENHANDS PROMPT LAB PROFILE: [^#]+ #\}\n"
    r".*?"
    r"\n\{# END OPENHANDS PROMPT LAB PROFILE #\}\n?",
    re.DOTALL,
)
text = block_pattern.sub("\n", text)

block = (
    f"{{# BEGIN OPENHANDS PROMPT LAB PROFILE: {profile_name} #}}\n"
    f"{profile}\n"
    "{# END OPENHANDS PROMPT LAB PROFILE #}\n"
)

idx = text.find(insert_marker)
if idx == -1:
    if not text.endswith("\n"):
        text += "\n"
    text = f"{text}\n{block}"
else:
    prefix = text[:idx]
    suffix = text[idx:]
    if prefix and not prefix.endswith("\n"):
        prefix += "\n"
    text = f"{prefix}{block}\n{suffix}"

if profile_marker not in text:
    raise SystemExit(f"profile marker was not injected into {system_path}")

system_path.write_text(text)
PY

grep -q "${PROFILE_MARKER}" "${PATCHED_PATH}/system_prompt.j2" || fail "patched system_prompt.j2 is missing profile marker"
grep -q "${PROFILE_MODE_MARKER}" "${PATCHED_PATH}/system_prompt.j2" || fail "patched system_prompt.j2 is missing Qwen mode marker"

if [[ "${dry_run}" -eq 1 ]]; then
  printf 'Target prompt directory: %s\n' "${target_dir}"
  printf 'Profile path: %s\n' "${profile_path}"
  printf 'Upstream snapshot path: %s\n' "${UPSTREAM_PATH}"
  printf 'Patched tree path: %s\n' "${PATCHED_PATH}"
  printf 'Backup path: <not created in dry-run>\n'
  printf 'Install status: dry run successful; target was not modified\n'
  printf 'Would back up to: %s.bak.<UTCSTAMP>\n' "${target_dir}"
  printf 'Would install patched tree contents over target prompt directory\n'
  printf 'Restore command: bash scripts/restore_openhands_prompt_backup.sh --backup-dir PATH_PRINTED_BY_INSTALLER --target-dir %q\n' "${target_dir}"
  exit 0
fi

utc_stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_path="${target_dir}.bak.${utc_stamp}"

if command -v rsync >/dev/null 2>&1; then
  mkdir -p "${backup_path}"
  rsync -a "${target_dir}/" "${backup_path}/"
else
  cp -a "${target_dir}" "${backup_path}"
fi

copy_tree_over_target "${PATCHED_PATH}" "${target_dir}"

grep -q "${PROFILE_MARKER}" "${target_dir}/system_prompt.j2" || fail "installed system_prompt.j2 is missing profile marker"
grep -q "${PROFILE_MODE_MARKER}" "${target_dir}/system_prompt.j2" || fail "installed system_prompt.j2 is missing Qwen mode marker"

printf 'Target prompt directory: %s\n' "${target_dir}"
printf 'Profile path: %s\n' "${profile_path}"
printf 'Upstream snapshot path: %s\n' "${UPSTREAM_PATH}"
printf 'Patched tree path: %s\n' "${PATCHED_PATH}"
printf 'Backup path: %s\n' "${backup_path}"
printf 'Install status: success\n'
printf 'Restore command: bash scripts/restore_openhands_prompt_backup.sh --backup-dir %q --target-dir %q\n' "${backup_path}" "${target_dir}"
