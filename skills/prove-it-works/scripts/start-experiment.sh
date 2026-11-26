#!/usr/bin/env bash
# start-experiment.sh — start serving variations. From here the flag is locked until completion.
#
#   bash scripts/start-experiment.sh --id 7
#
# Output: {"ok":true,"experiment_id":7,"status":"running","started_at":"2026-11-26T12:00:00Z",
#          "flag":"landing_headline","dashboard":"https://app.flagsmith.com/project/1/environment/ser.xxx/experiments/7"}
. "$(dirname "$0")/_lib.sh"

ID=
while [[ $# -gt 0 ]]; do case $1 in --id) ID=$2; shift 2 ;; *) fail "Unknown argument: $1" ;; esac; done
[[ $ID =~ ^[0-9]+$ ]] || fail "--id <experiment id> is required"

check_cli
resolve_context
PROJECT_ID=$(fsq '.id' project get "$PROJECT")
EXP="api/v1/environments/$ENV_KEY/experiments/$ID/"

STATUS=$(apiq '.status' "$EXP")
FLAG=$(apiq '.feature.name' "$EXP")
case $STATUS in
  created|paused) api "${EXP}start/" -X POST >/dev/null ;;
  running) ;;  # already running: idempotent
  completed) fail "Experiment $ID is completed; results are final and it cannot be restarted." "Create a new experiment with create-experiment.sh" ;;
  *) fail "Experiment $ID has unexpected status '$STATUS'." ;;
esac

STATUS=$(apiq '.status' "$EXP")
STARTED=$(apiq '.started_at // ""' "$EXP")
[[ $STATUS == running ]] || fail "Start was accepted but status is '$STATUS', not running."

printf '{"ok":true,"experiment_id":%s,"status":%s,"started_at":%s,"flag":%s,"dashboard":%s}\n' \
  "$ID" "$(json_str "$STATUS")" "$(json_str "$STARTED")" "$(json_str "$FLAG")" \
  "$(json_str "$DASHBOARD/project/$PROJECT_ID/environment/$ENV_KEY/experiments/$ID")"
