#!/usr/bin/env bash
# Shared helpers for prove-it-works scripts. Source it, don't run it.
#
# Contract every script keeps: exactly ONE JSON line on stdout.
#   success -> {"ok":true, ...}            exit 0
#   failure -> {"ok":false,"error":"..."}  exit 1
# No API payload ever reaches the agent unfiltered; extraction happens here with the CLI's
# built-in --jq, so the only dependencies are bash and the Flagsmith CLI (v2+).
set -euo pipefail

exec 3>&1   # fd 3 = the real stdout, so fail() is visible even from inside $(...)

json_str() { # json_str <text> -> "escaped"
  local s=$1
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\r'/\\r}; s=${s//$'\t'/\\t}
  printf '"%s"' "$s"
}

fail() { # fail <message> [hint]
  local msg=$1 hint=${2:-}
  if [[ -n $hint ]]; then
    printf '{"ok":false,"error":%s,"hint":%s}\n' "$(json_str "$msg")" "$(json_str "$hint")" >&3
  else
    printf '{"ok":false,"error":%s}\n' "$(json_str "$msg")" >&3
  fi
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || fail "'$1' is not installed." "${2:-}"; }

trim_err() { tr -d '\r' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ +| +$//g' | cut -c1-400; }

# fs <cli args...>: run the CLI; on failure, report its (trimmed) stderr and stop.
fs() {
  local out
  if ! out=$(flagsmith "$@" 2>"$PIW_TMP/err"); then
    fail "flagsmith ${1:-} ${2:-} failed: $(trim_err <"$PIW_TMP/err")"
  fi
  printf '%s' "$out"
}

# fsq <jq-expr> <cli args...>: fs with --jq, with surrounding quotes stripped from string results.
fsq() {
  local expr=$1; shift
  local v
  v=$(fs "$@" --jq "$expr")
  v=${v#\"}; v=${v%\"}
  printf '%s' "$v"
}

# api <path> [flags...]: Admin API call with the CLI's credentials (GET unless -X/-F/--input given).
api() { fs api "$@" --json; }
apiq() { local expr=$1; shift; fsq "$expr" api "$@"; }

check_cli() {
  need flagsmith "Install: curl -fsSL https://get.flagsmith.com | sh   (or: brew install Flagsmith/tap/flagsmith)"
  local v; v=$(flagsmith --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | cut -d. -f1)
  [[ ${v:-0} -ge 2 ]] || fail "Flagsmith CLI v2+ required (found: $(flagsmith --version 2>/dev/null))." "Upgrade: curl -fsSL https://get.flagsmith.com | sh"
}

# Fill ENV_KEY, PROJECT, API_URL, DASHBOARD from flagsmith.json / -e -p flags / env vars.
resolve_context() {
  ENV_KEY=$(fsq '.environment.value // ""' config)
  PROJECT=$(fsq '.project.value // ""' config)
  API_URL=$(fsq '.apiUrl.value // ""' config)
  [[ -n $ENV_KEY && $ENV_KEY != null ]] || fail "No environment selected." "Run: flagsmith init --project <name> --environment <client-side key>   or set FLAGSMITH_ENVIRONMENT"
  [[ -n $PROJECT && $PROJECT != null ]] || fail "No project selected." "Run: flagsmith init --project <name> --environment <client-side key>   or set FLAGSMITH_PROJECT"
  case $API_URL in
    https://api.flagsmith.com*) DASHBOARD=https://app.flagsmith.com ;;
    *) DASHBOARD=$(printf '%s' "${API_URL%/}" | sed -E 's#/api(/v1)?$##') ;;
  esac
  DASHBOARD=${PIW_DASHBOARD:-$DASHBOARD}
}

# Environment names that mean "real users". Scripts add friction, SKILL.md adds a louder gate.
production_like() { [[ $1 =~ ^([Pp]rod|[Pp]roduction|[Ll]ive|[Pp]rd) ]] && echo true || echo false; }

PIW_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t piw)
trap 'rm -rf "$PIW_TMP"' EXIT
STATE_DIR=${PIW_STATE_DIR:-.prove-it-works}
