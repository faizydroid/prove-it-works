---
name: prove-it-works
description: Run a Flagsmith A/B test end to end from a coding agent and ship the winner with no flag debt left behind. Use when asked to A/B test a change, set up or start a Flagsmith experiment, instrument exposures and conversion events, check experiment results (lift, credible interval, win probability), roll out a winning variant, or clean up and archive a flag after an experiment. Built on the Flagsmith CLI v2 plus six bundled scripts that each return one JSON line. A human approves every change that users can see.
license: MIT
compatibility: Flagsmith CLI v2+ (logged in via `flagsmith login`, or FLAGSMITH_API_KEY), bash, git. gh for the cleanup PR. Node 18+ only for scripts/simulate-traffic.mjs. Flagsmith Cloud or self-hosted (set FLAGSMITH_API_URL).
metadata:
  author: faizydroid
  flagsmith-job: prove-it-works
  hackathon: toggle-wars-2026
---

# prove-it-works

Take a change from "I think B is better" to "B is live for everyone and the flag is gone". Flagsmith
Experimentation is the judge; you drive the CLI; a human holds the keys.

## Rules

- Every script prints **one JSON line**. Read it. Don't re-fetch what it already told you.
- `"ok":false` → stop, show the human `error` (and `hint`) verbatim. Don't guess or work around it.
- **GATE** steps change what users see or what the project contains. Before each, say exactly what
  will change, **in which environment** (name it), and wait for an explicit yes. No yes, no action.
- **Production.** Write scripts refuse a production-like environment (Production, prod, live, prd)
  unless you pass `--confirm-env "<exact name>"`, and refuse any write if that name differs from
  the environment they resolved. Pass it only after the human approved that environment by name,
  and say "this affects live users". Every result reports `environment.source`: `config` is
  `flagsmith.json`, `env` is a `FLAGSMITH_ENVIRONMENT` variable. If that's not what you expected, stop.
- Never print, copy or commit API keys. Scripts use the CLI's own credentials.
- One active experiment per flag. The scripts are idempotent; re-run them, don't improvise.
- Run scripts with `bash <skill>/scripts/<name>.sh` from the app's repo root (where `flagsmith.json` lives).

## Steps

### 1. Preflight (read-only)
`bash scripts/preflight.sh` → `{cli, user, project, environment:{key,name,production_like}, warehouse:{status}, dashboard}`
- `warehouse.status` `created`, `pending_connection` or `connected`: proceed (the first event
  from the app flips it to connected).
- `none`: ask the human; with a yes, `bash scripts/preflight.sh --enable-warehouse` creates the
  Flagsmith-managed warehouse (**GATE**). Otherwise send them to
  https://docs.flagsmith.com/experimentation/connect-a-warehouse and stop.
- `errored`: show `warehouse.detail`, stop.
- "No project/environment selected": ask which, then
  `flagsmith init --project <name> --environment <client-side key>`.

### 2. Design the test (ask, then confirm)
Ask, then wait:
1. **What changes?** Find the component/file that renders it.
2. **What counts as success?** Find where it happens in code. That is the conversion event.
3. Check the SDK can send events (versions in `references/instrumentation.md`). If not, say so and stop.

Propose: flag name (snake_case), control value, each variant `key=value` (keys short, lowercase;
`control` is reserved), event name (case-sensitive, exactly what the code will send), rollout %
(default 100), split (default even), and a one-sentence hypothesis: change, metric, expected size,
timeframe. Confirm the whole plan before step 3.

### 3. Create flag, variants, metric, experiment — GATE
```
bash scripts/create-experiment.sh --flag <flag> --control "<value>" --variant <key>="<value>" \
  --event <event> --name "<experiment name>" --hypothesis "<sentence>" [--weight <key>=<pct>] [--confirm-env "<name>"]
```
→ `{flag, feature_id, variants:{key:id}, metric_id, experiment_id, status:"created", reused, environment, dashboard}`
The experiment is created at 0% rollout, so nothing is served yet: everyone keeps getting control.
Existing flag/variants/metric/unfinished experiment are reused, not duplicated. The flag and its
variants are project-wide; the metric and experiment belong to this environment.

### 4. Instrument the code — GATE (show the diff plan first)
Follow `references/instrumentation.md` for the app's SDK. Three edits, nothing more:
- init with events enabled, using the environment key the app already uses for flags;
- identify the user, then call the **experiment flag** API where the variation is actually seen
  (that call records the exposure) and render by its `value`;
- track the conversion event where success happens; flush before exit/navigation.
Same identifier for flags and events or exposures and conversions can't be joined. Keys stay out of git.

### 5. Start — GATE
`bash scripts/start-experiment.sh --id <experiment_id> [--rollout 100] [--confirm-env "<name>"]`
→ `{status:"running", rollout, started_at, environment}`. Starts it, then raises the rollout from
0% to `--rollout`. Variants are served from this moment. The flag is locked until completion.

### 6. Traffic
- Real users: wait. Under 50 identities per variant (or 5 conversions) the verdict is `collecting`.
- Smoke test / demo, never production:
  `npm install --prefix scripts` once, then
  `node scripts/simulate-traffic.mjs --env <client key> --flag <flag> --event <event> --users 400 --rates control=0.08,<key>=0.11`
  It prints `rates_used`; repeat them in any write-up so simulated data is never mistaken for real.

### 7. Verdict
`bash scripts/results.sh --id <id> --refresh` → `{as_of, srm_warning, variants:{key:{n,conversions,rate,lift,ci,chance_to_win}}, verdict, winner, reason}`
Refresh is allowed every 5 minutes; a `retry_after_s` means wait, not loop.

| verdict | do |
|---|---|
| `no_results`, `collecting` | wait; re-check later |
| `inconclusive` | wait, or offer the human `--decision control` to stop and keep control |
| `srm` | traffic didn't split as configured. Do **not** act on the numbers; find the cause |
| `winner` | step 8 with `--variant <winner>` |
| `control_wins` | step 8 with `--decision control` |

Say it in plain words, e.g. "ai converted 11.1% vs 8.0%: +39% lift, 95% interval +5%..+72%, 97% chance it really is better."

### 8. Roll out — GATE (quote the numbers in the gate text)
`bash scripts/rollout-winner.sh --id <id> --variant <key>` | `--decision control` | `--decision disable`
(plus `--confirm-env "<name>"` for production)
→ `{status:"completed", serving, rollback, rollback_file}`
The script refuses unless `results.sh` names that variant the winner; never on `srm` or `collecting`.
`--override "<the human's exact words>"` is accepted only for `inconclusive` and is recorded in the
rollback file. It saves the flag state first and prints the one-line rollback. Completion is final:
results freeze, the flag unlocks, the environment default serves the decision to 100%.
Verify: `flagsmith eval <flag> --identity <any new id> --json` shows the winner. Unidentified
requests still get control's value (weights apply per identity), which is why step 9 hardcodes it.

### 9. Remove the flag from code — GATE (open the PR)
Hardcode the winner: delete the losing branch and the experiment-flag call; keep conversion
tracking only if the product wants the analytics. `git grep -n <flag>` until only docs remain. Then
```
git switch -c chore/remove-<flag> && git commit -am "Remove <flag>: <winner> at 100% (experiment <id>)" \
  && gh pr create --fill --body "Experiment: <dashboard>. <reason>"
```
Don't merge it yourself.

### 10. Archive — after the PR merges
`bash scripts/archive-flag.sh --flag <flag> --pr <number>` → `{archived:true, pr_state:"MERGED", code_references:0}`
Refuses unless the PR is merged, `git grep` finds no code reference, and no experiment on the flag
is unfinished in any environment (archiving is project-wide). Archive, not delete: the
experiments and their history stay.

## Reporting to the human
After each step, one short paragraph: what changed, the IDs, the dashboard link, what comes next.
No JSON dumps, no API payloads.

## When things go wrong
- `409 An active experiment already exists` → `results.sh` on it; finish it before creating another.
- Exposures stay at 0 → `references/troubleshooting.md`.
- Endpoint details, payloads, result shapes → `references/api.md`.
