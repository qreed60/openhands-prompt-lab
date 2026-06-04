#!/usr/bin/env bash
set -euo pipefail

DEFAULT_TARGET_DIR="/home/qreed/.local/share/uv/tools/openhands/lib/python3.12/site-packages/openhands/sdk/agent/prompts"

target_dir="${DEFAULT_TARGET_DIR}"
backup_dir=""

usage() {
  cat <<'EOF'
Usage: bash scripts/restore_openhands_prompt_backup.sh --backup-dir PATH [--target-dir PATH]

Options:
  --backup-dir PATH  Backup prompt directory created by the installer.
  --target-dir PATH  OpenHands prompt directory to restore.
  -h, --help         Show this help.
EOF
}

fail() {
  printf 'Restore failure: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-dir)
      [[ $# -ge 2 ]] || fail "--backup-dir requires a path"
      backup_dir="$2"
      shift 2
      ;;
    --target-dir)
      [[ $# -ge 2 ]] || fail "--target-dir requires a path"
      target_dir="$2"
      shift 2
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

[[ -n "${backup_dir}" ]] || fail "--backup-dir is required"
[[ -f "${backup_dir}/system_prompt.j2" ]] || fail "backup system_prompt.j2 is missing: ${backup_dir}/system_prompt.j2"
[[ -d "${target_dir}" ]] || fail "target directory is missing: ${target_dir}"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${backup_dir}/" "${target_dir}/"
else
  cp -a "${backup_dir}/." "${target_dir}/"
fi

[[ -f "${target_dir}/system_prompt.j2" ]] || fail "restored system_prompt.j2 is missing: ${target_dir}/system_prompt.j2"

printf 'Restore status: success\n'
printf 'Backup directory: %s\n' "${backup_dir}"
printf 'Target prompt directory: %s\n' "${target_dir}"
