# prove-it-works

**A Flagsmith Agent Skill that takes a coding agent through a whole A/B test: flag → metric →
experiment → traffic → verdict → rollout → cleanup PR → archive. A human approves every change
users can see. Then it was used to A/B test its own landing page.**

Built solo for [Toggle Wars: The Flagsmith Experimentation Hackathon](https://www.wemakedevs.org/hackathons/flagsmith)
(Nov 26–29, 2026).

- Live experiment: **https://faizydroid.github.io/prove-it-works/** (the headline is the test)
- The skill: [`skills/prove-it-works/`](skills/prove-it-works/)
- Demo video: _coming Sunday_
- Experiment pre-registration, decision rule and results: [`docs/experiment.md`](docs/experiment.md)

## Why

Coding agents can already wire a feature flag in. What they can't do well is the part that
comes after: prove the change helped, ship the winner, and delete the flag so the codebase
doesn't rot. Each of those is a chain of CLI calls, API payloads and judgement calls about
statistics, and every one of them is a chance to touch production by accident.

`prove-it-works` packages that whole job as one skill. The agent reads ~2k tokens of
instructions, runs six scripts that each hand back **one JSON line**, and stops at five gates
to ask a human.

## The job

| # | Step | Script | Gate |
|---|---|---|---|
| 1 | Preflight: CLI, login, project, environment, warehouse | `preflight.sh` | read-only |
| 2 | Design: what changes, what counts as success, hypothesis | (conversation) | confirm plan |
| 3 | Create multivariate flag, keyed variants, metric, experiment (not started) | `create-experiment.sh` | **GATE** |
| 4 | Instrument: exposure where the variation is seen, conversion where success happens | (code edits) | **GATE** |
| 5 | Start the experiment; the flag locks | `start-experiment.sh` | **GATE** |
| 6 | Traffic: real users, or scripted identities with the rates printed on the tin | `simulate-traffic.mjs` | never on prod |
| 7 | Verdict: lift, 95% credible interval, win probability, sample-ratio check | `results.sh` | |
| 8 | Roll out the winner to 100% (or keep control, or disable) | `rollout-winner.sh` | **GATE** |
| 9 | Delete the losing code path, open the PR | (code edits + `gh`) | **GATE** |
| 10 | Archive the flag, only after the PR merged and no code references it | `archive-flag.sh` | |

### What the agent sees

Real output from the pipeline smoke test on Flagsmith Cloud (Nov 26): 600 **simulated** users,
conversion rates set to 8% vs 16% by the simulator. Creating the flag to reading the verdict took
about four minutes, most of it waiting for events to land.

```
$ bash scripts/results.sh --id 709 --refresh
{"ok":true,"experiment_id":709,"status":"running","flag":"piw_smoke","as_of":"2026-11-26T18:42:23.298084Z",
 "is_final":false,"srm_p_value":0.2207,"srm_source":"local","srm_warning":false,
 "variants":{"control":{"n":315,"conversions":33,"rate":0.1048},
             "b":{"n":285,"conversions":52,"rate":0.1825,"lift":0.742,"ci":[0.034,1.449],"chance_to_win":0.98}},
 "verdict":"winner","winner":"b",
 "reason":"b: 98% chance to beat control (+74% lift, 95% CI +3%..+145%)",
 "dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/709"}

$ bash scripts/rollout-winner.sh --id 709 --variant b
{"ok":true,"experiment_id":709,"status":"completed","flag":"piw_smoke","decision":"variant","serving":"b",
 "verdict":"winner","rollback":"flagsmith flag update piw_smoke --weight b=0",
 "rollback_file":".prove-it-works/rollback-piw_smoke-20261126T184714Z.json", ...}
```

`srm_source: local`: Flagsmith's beta checks the traffic split against the flag's
environment-default weights, not the experiment's split. Variants added with weight 0 (as
Flagsmith's own setup prompt does) make that check return nothing. `results.sh` runs the same
chi-squared test against the experiment's own split instead.

No raw API payloads ever reach the model. Extraction happens inside the scripts with the CLI's
built-in `--jq`, so the only runtime dependencies are bash and the Flagsmith CLI (Node only for
the traffic simulator).

### Safety

- `rollout-winner.sh` refuses to ship a variant unless `results.sh` names it the winner
  (≥95% chance to win **and** the credible interval excludes zero). It never ships on a
  sample-ratio mismatch or while still collecting data. The only escape hatch,
  `--override "<the human's exact words>"`, works for *inconclusive* only and is written into the
  rollback file next to the numbers it overrode.
- Before any rollout the current flag state is saved to `.prove-it-works/rollback-*.json` and the
  one-line rollback command is printed.
- `archive-flag.sh` refuses unless the cleanup PR is `MERGED`, `git grep` finds no code reference to
  the flag, and no experiment on the flag is unfinished. It archives; it never deletes.
- Write scripts refuse a production-like environment (Production, prod, live, prd) unless the
  agent passes `--confirm-env "<exact name>"` after the human approved it by name, and refuse any
  write whose confirmed name differs from the environment they actually resolved. Every result
  says which environment it touched and where that came from (`flagsmith.json` or an environment
  variable). This guard exists because a stray `FLAGSMITH_ENVIRONMENT` variable once pointed a test
  run at Production during development.
- Experiments are created at 0% rollout and only start serving when `start-experiment.sh` raises
  it. Flagsmith applies an experiment's rollout as soon as it is created, so creating at 100%
  would show the variants before anyone approved the start.
- Archiving is project-wide, so `archive-flag.sh` checks every environment for unfinished
  experiments, not just the current one.
- Scripts are idempotent: re-running after a failure reuses the flag, variants, metric and
  experiment instead of duplicating them. Every failure is `{"ok":false,"error":...,"hint":...}`.

### Token count

Measured on the demo run (Claude Code, `claude -p … --output-format json`, usage field):

_To be filled after the demo run on Saturday._

## Install the skill

Copy `skills/prove-it-works/` into your agent's skills directory and it is picked up by name:

| Agent | Path |
|---|---|
| Claude Code | `.claude/skills/prove-it-works/` (project) or `~/.claude/skills/prove-it-works/` |
| Kiro | `.kiro/skills/prove-it-works/` or `~/.kiro/skills/prove-it-works/` |
| Anything following the [Agent Skills spec](https://agentskills.io/specification) | its skills folder |

Requirements: [Flagsmith CLI v2](https://docs.flagsmith.com/integrating-with-flagsmith/CLI)
(`flagsmith login`), bash, git, `gh` for the PR step, Node 18+ only for `simulate-traffic.mjs`
(`npm install --prefix skills/prove-it-works/scripts`). Works against Flagsmith Cloud or self-hosted.

Then just ask: *"A/B test the checkout button copy with Flagsmith, success is a completed purchase."*

## The experiment this repo ran on itself

The landing page in [`site/`](site/) is a real A/B test on real visitors, set up with this skill.
Full pre-registration, decision rule and (on Sunday) results: [`docs/experiment.md`](docs/experiment.md).

- **Hypothesis:** opening with the reader's problem ("Stop guessing which version wins. Let your
  agent prove it.") beats describing the product ("Run A/B tests from your coding agent.") on
  click-through to the GitHub repo by at least 20% relative.
- **Flag:** `landing_headline` (multivariate). The headline text *is* the flag value.
- **Metric:** `cta_click`, occurrence per identity: did this visitor click "Get the skill" at least once.
- **Traffic:** Production gets real visitors only; our own browsers are excluded with `?internal`.
  Development has its own experiment for local testing and scripted traffic, never mixed in.

## Repo layout

```
skills/prove-it-works/     the skill: SKILL.md, scripts/, references/
site/                      the landing page under test (served from the gh-pages branch)
docs/                      experiment write-up, demo-run transcript and token count
```

Deploy the site after editing `site/`: `git subtree push --prefix site origin gh-pages`.

## License

MIT
