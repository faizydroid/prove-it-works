# results.jq — turns GET .../experiments/<id>/results/ into a verdict. Used by results.sh.
# Input:  {"results": null | {"as_of","is_final","payload":{"srm_p_value","metrics":[{"metric_id","variants","inference"}]}}}
# Needs:  def metric_index: <index of the metric to judge>;   (prepended by results.sh; 0 = primary metric)
# Thresholds mirror Flagsmith's results page: inference appears at 50+ identities and 5+ conversions
# per variant; a variant "wins" at a 95% chance to beat control; SRM below p = 0.001 voids the test.

def r3: (. * 1000 | round) / 1000;
def r4: (. * 10000 | round) / 10000;
def pct: (. * 100 | round);
def signed: if . >= 0 then "+\(.)" else "\(.)" end;

# Chi-squared survival function for integer degrees of freedom; same recurrence as Flagsmith's stats.py.
def chi2_sf($stat; $df):
  if $stat <= 0 then 1
  else ($stat / 2) as $y
  | (if $df % 2 == 1 then {a: 0.5, s: ($y | sqrt | erfc)} else {a: 1, s: (0 - $y | exp)} end)
  | until(.a + 1 > $df / 2; .s += ((.a * ($y | log) - $y - (.a + 1 | lgamma)) | exp) | .a += 1)
  | .s
  end;

# SRM against the experiment's own split (`expected`, prepended by results.sh). Flagsmith's beta
# reads the split from the environment default, which is 0% for variants of API-created experiments,
# so its srm_p_value stays null; this fills the gap. Needs 100+ identities, like Flagsmith's.
def srm_local($v):
  (expected | to_entries | map(select(.value > 0))) as $e
  | ([$e[] | $v[.key].n // 0] | add // 0) as $total
  | if ($e | length) < 2 or $total < 100 then null
    else ([$e[] | (($v[.key].n // 0) - $total * .value) as $d | $d * $d / ($total * .value)] | add) as $stat
    | chi2_sf($stat; ($e | length) - 1)
    end;

.results as $r
| if $r == null or $r.payload == null then
    { as_of: ($r.as_of // null), is_final: ($r.is_final // false),
      srm_p_value: null, srm_warning: false, variants: {},
      verdict: "no_results", winner: null,
      reason: "No results computed yet. Run with --refresh (allowed every 5 minutes)." }
  else
    ($r.payload.metrics[metric_index] // {}) as $m
    | ($m.variants // {}) as $v
    | ($m.inference // {}) as $inf
    | ($v | with_entries(.value |= { n: .n, conversions: (.sum | round),
                                      rate: (if .n > 0 then (.sum / .n | r4) else 0 end) })) as $base
    | ($inf | with_entries(select(.value != null))
            | with_entries(.value |= { lift: (.lift | r3), ci: [(.ci_low | r3), (.ci_high | r3)],
                                       chance_to_win: (.chance_to_win | r3) })) as $stats
    | ($base | with_entries(.value += ($stats[.key] // {}))) as $variants
    | (if $r.payload.srm_p_value != null then "flagsmith" else "local" end) as $srm_source
    | (($r.payload.srm_p_value // srm_local($base)) | if . == null then null else r4 end) as $srm
    | ($srm != null and $srm < 0.001) as $srm_bad
    | ($inf | length == 0 or (to_entries | any(.value == null))) as $collecting
    | ($stats | to_entries | sort_by(-.value.chance_to_win) | .[0]) as $best
    | ( if $srm_bad then "srm"
        elif $collecting then "collecting"
        elif $best.value.chance_to_win >= 0.95 and $best.value.ci[0] > 0 then "winner"
        elif ($stats | to_entries | all(.value.chance_to_win <= 0.05 and .value.ci[1] < 0)) then "control_wins"
        else "inconclusive" end ) as $verdict
    | { as_of: $r.as_of, is_final: $r.is_final, srm_p_value: $srm, srm_source: (if $srm == null then null else $srm_source end),
        srm_warning: $srm_bad, variants: $variants, verdict: $verdict,
        winner: (if $verdict == "winner" then $best.key elif $verdict == "control_wins" then "control" else null end),
        reason: (
          if $verdict == "srm" then
            "Sample ratio mismatch (p=\($srm)): traffic did not split as configured. Do not act on these numbers."
          elif $verdict == "collecting" then
            "Collecting data: every variant needs 50+ identities and 5+ conversions. So far: \($variants | to_entries | map("\(.key) \(.value.n) seen/\(.value.conversions) converted") | join(", "))."
          else
            "\($best.key): \($best.value.chance_to_win | pct)% chance to beat control (\($best.value.lift | pct | signed)% lift, 95% CI \($best.value.ci[0] | pct | signed)%..\($best.value.ci[1] | pct | signed)%)"
          end ) }
  end
