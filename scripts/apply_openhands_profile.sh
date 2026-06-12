#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
profiles_dir="${repo_root}/profiles"
openhands_dir="${HOME}/.openhands"
profile_name=""
dry_run=0
force=0

usage() {
  cat <<'EOF'
Usage: bash scripts/apply_openhands_profile.sh --profile NAME [options]

Options:
  --profile NAME         Profile directory under profiles/.
  --openhands-dir PATH   OpenHands config directory. Default: ~/.openhands.
  --dry-run              Print actions without writing files.
  --force                Accepted for explicit overwrite intent; existing files are always backed up.
  -h, --help             Show this help.
EOF
}

fail() {
  printf 'Profile apply failure: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || fail "--profile requires a name"
      profile_name="$2"
      shift 2
      ;;
    --openhands-dir)
      [[ $# -ge 2 ]] || fail "--openhands-dir requires a path"
      openhands_dir="$2"
      shift 2
      ;;
    --dry-run)
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

[[ -n "${profile_name}" ]] || fail "--profile is required"
case "${profile_name}" in
  */*|*..*|'')
    fail "profile name must be a simple directory name"
    ;;
esac

profile_dir="${profiles_dir}/${profile_name}"
settings_src="${profile_dir}/agent_settings.json"
system_prompt_src="${profile_dir}/system_prompt.j2"
security_policy_src="${profile_dir}/security_policy.j2"

[[ -d "${profile_dir}" ]] || fail "profile does not exist: ${profile_dir}"
[[ -f "${settings_src}" ]] || fail "profile is missing agent_settings.json: ${settings_src}"
[[ -f "${system_prompt_src}" ]] || fail "profile is missing system_prompt.j2: ${system_prompt_src}"
[[ -f "${security_policy_src}" ]] || fail "profile is missing security_policy.j2: ${security_policy_src}"

python3 -m json.tool "${settings_src}" >/dev/null || fail "invalid JSON: ${settings_src}"

settings_dest="${openhands_dir}/agent_settings.json"
system_prompt_dest="${openhands_dir}/system_prompt.j2"
security_policy_dest="${openhands_dir}/security_policy.j2"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="${openhands_dir}/backups/prompt-lab/${stamp}"

if [[ "${dry_run}" -eq 1 ]]; then
  printf 'Profile: %s\n' "${profile_name}"
  printf 'OpenHands dir: %s\n' "${openhands_dir}"
  printf 'Dry run: true\n'
  printf 'Force: %s\n' "${force}"
  printf 'Validated JSON: %s\n' "${settings_src}"
  printf 'Would create backup dir: %s\n' "${backup_dir}"
  printf 'Would copy exact files:\n'
  printf '  %s -> %s\n' "${settings_src}" "${settings_dest}"
  printf '  %s -> %s\n' "${system_prompt_src}" "${system_prompt_dest}"
  printf '  %s -> %s\n' "${security_policy_src}" "${security_policy_dest}"
  printf 'Apply status: dry run successful; no files were modified\n'
  exit 0
fi

mkdir -p "${openhands_dir}"
mkdir -p "${backup_dir}"

backup_if_present() {
  local src="$1"
  local label="$2"
  if [[ -e "${src}" ]]; then
    cp -p "${src}" "${backup_dir}/${label}"
  fi
}

backup_if_present "${settings_dest}" "agent_settings.json"
backup_if_present "${system_prompt_dest}" "system_prompt.j2"
backup_if_present "${security_policy_dest}" "security_policy.j2"

cp "${settings_src}" "${settings_dest}"
cp "${system_prompt_src}" "${system_prompt_dest}"
cp "${security_policy_src}" "${security_policy_dest}"

printf 'Profile: %s\n' "${profile_name}"
printf 'OpenHands dir: %s\n' "${openhands_dir}"
printf 'Backup dir: %s\n' "${backup_dir}"
printf 'Apply status: success\n'
printf 'Restore command: cp %q/agent_settings.json %q; cp %q/system_prompt.j2 %q; cp %q/security_policy.j2 %q\n' \
  "${backup_dir}" "${settings_dest}" \
  "${backup_dir}" "${system_prompt_dest}" \
  "${backup_dir}" "${security_policy_dest}"
