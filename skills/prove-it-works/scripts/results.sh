#!/usr/bin/env bash
# results.sh — the verdict, computed from Flagsmith's Bayesian results, as one line.
#
#   bash scripts/results.sh --id 7 [--refresh] [--metric <metric id>]
#
#   --refresh  asks Flagsmith to recompute first (allowed once per 5 minutes) and waits up to
#              ~90s for the new numbers. If throttled, the current numbers are returned with
#              "retry_after_s" so the caller can wait instead of looping.
#
# Output:
#   {"ok":true,"experiment_id":7,"status":"running","flag":"landing_headline","as_of":"...",
#    "is_final":false,"srm_p_value":0.83,"srm_warning":false,
#    "variants":{"control":{"n":312,"conversions":25,"rate":0.0801},
#                "ai":{"n":305,"conversions":34,"rate":0.1115,"lift":0.392,"ci":[0.05,0.72],"chance_to_win":0.97}},
#    "verdict":"winner","winner":"ai","reason":"ai: 97% chance to beat control (+39% lift, 95% CI +5%..+72%)",
#    "dashboard":"https://app.flagsmith.com/project/1/environment/ser.xxx/experiments/7"}
#
# verdict:
#   no_results    nothing computed yet -> run with --refresh
#   collecting    under 50 identities or 5 conversions in some variant -> keep running
#   srm           traffic did not split as configured (p < 0.001) -> do NOT act on these numbers
#   winner        a variant has >= 95% chance to beat control and its interval excludes 0
#   control_wins  every variant has <= 5% chance to beat control and its interval excludes 0
#   inconclusive  anything else -> keep running, or stop and keep control
. "$(dirname "$0")/_lib.sh"

ID= REFRESH=false METRIC_ID=
while [[ $# -gt 0 ]]; do
  case $1 in
    --id) ID=$2; shift 2 ;;
    --refresh) REFRESH=true; shift ;;
    --metric) METRIC_ID=$2; shift 2 ;;
    *) fail "Unknown argument: $1" ;;
  esac
done
[[ $ID =~ ^[0-9]+$ ]] || fail "--id <experiment id> is required"

check_cli
resolve_context
PROJECT_ID=$(fsq '.id' project get "$PROJECT")
EXP="api/v1/environments/$ENV_KEY/experiments/$ID/"

STATUS=$(apiq '.status' "$EXP")
FLAG=$(apiq '.feature.name' "$EXP")
[[ $STATUS != created ]] && [[ -n $STATUS ]] || fail "Experiment $ID has not started (status: $STATUS); there are no results yet." "Run start-experiment.sh --id $ID first"

RETRY_JSON=""
if [[ $REFRESH == true ]]; then
  prev=$(apiq '.results.as_of // ""' "${EXP}results/")
  if flagsmith api "${EXP}results/refresh/" -X POST --json >/dev/null 2>"$PIW_TMP/err"; then
    for _ in $(seq 1 18); do
      sleep 5
      cur=$(apiq '.results.as_of // ""' "${EXP}results/")
      [[ -n $cur && $cur != "$prev" ]] && break
    done
  else
    err=$(trim_err <"$PIW_TMP/err")
    if [[ $err =~ ([0-9]+)\ second ]]; then
      RETRY_JSON=",\"retry_after_s\":${BASH_REMATCH[1]}"
    elif [[ $err == *final* ]]; then
      : # completed experiment: results are frozen, nothing to refresh
    else
      fail "Refresh failed: $err"
    fi
  fi
fi

# Pick the metric: --metric <id>, else the experiment's first (primary) metric.
if [[ -n $METRIC_ID ]]; then
  PICK="(.results.payload.metrics | map(.metric_id) | index($METRIC_ID)) // 0"
else
  PICK="0"
fi

SUMMARY=$(api "${EXP}results/" --jq "
  .results as \$r
  | if \$r == null or \$r.payload == null then
      {as_of: null, is_final: false, srm_p_value: null, srm_warning: false, variants: {}, verdict: \"no_results\", winner: null,
       reason: \"No results computed yet. Run with --refresh (allowed every 5 minutes).\"}
    else
      (\$r.payload.metrics[($PICK)]) as \$m
      | (\$m.variants // {}) as \$v
      | (\$m.inference // {}) as \$inf
      | (\$v | with_entries(.value |= {n: .n, conversions: (.sum | round), rate: (if .n > 0 then ((.sum / .n * 10000) | round) / 10000 else 0 end)})) as \$base
      | (\$inf | with_entries(select(.value != null))
          | with_entries(.value |= {lift: ((.lift * 1000) | round) / 1000,
                                    ci: [((.ci_low * 1000) | round) / 1000, ((.ci_high * 1000) | round) / 1000],
                                    chance_to_win: ((.chance_to_win * 1000) | round) / 1000})) as \$stats
      | (\$base | with_entries(.value += (\$stats[.key] // {}))) as \$variants
      | \$r.payload.srm_p_value as \$srm
      | (\$srm != null and \$srm < 0.001) as \$srm_bad
      | (\$stats | to_entries | sort_by(-.value.chance_to_win) | .[0]) as \$best
      | (if \$srm_bad then \"srm\"
         elif (\$stats | length) == 0 then \"collecting\"
         elif \$best.value.chance_to_win >= 0.95 and \$best.value.ci[0] > 0 then \"winner\"
         elif (\$stats | to_entries | all(.value.chance_to_win <= 0.05 and .value.ci[1] < 0)) then \"control_wins\"
         else \"inconclusive\" end) as \$verdict
      | {as_of: \$r.as_of, is_final: \$r.is_final, srm_p_value: \$srm, srm_warning: \$srm_bad, variants: \$variants, verdict: \$verdict,
         winner: (if \$verdict == \"winner\" then \$best.key elif \$verdict == \"control_wins\" then \"control\" else null end),
         reason: (if \$verdict == \"srm\" then \"Sample ratio mismatch (p=\(\$srm)): traffic did not split as configured. Do not act on these numbers.\"
                  elif \$verdict == \"collecting\" then \"Collecting data: each variant needs 50+ identities and 5+ conversions before inference. Identities so far: \(\$variants | to_entries | map(\"\(.key)=\(.value.n)\") | join(\", \")).\"
                  else \"\(\$best.key): \((\$best.value.chance_to_win * 100) | round)% chance to beat control (\(if \$best.value.lift >= 0 then \"+\" else \"\" end)\((\$best.value.lift * 100) | round)% lift, 95% CI \(if \$best.value.ci[0] >= 0 then \"+\" else \"\" end)\((\$best.value.ci[0] * 100) | round)%..\(if \$best.value.ci[1] >= 0 then \"+\" else \"\" end)\((\$best.value.ci[1] * 100) | round)%)\" end)}
    end")

INNER=${SUMMARY#\{}; INNER=${INNER%\}}   # splice the jq object into ours
printf '{"ok":true,"experiment_id":%s,"status":%s,"flag":%s%s,%s,"dashboard":%s}\n' \
  "$ID" "$(json_str "$STATUS")" "$(json_str "$FLAG")" "$RETRY_JSON" "$INNER" \
  "$(json_str "$DASHBOARD/project/$PROJECT_ID/environment/$ENV_KEY/experiments/$ID")"
