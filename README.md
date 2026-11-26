# prove-it-works

**A Flagsmith Agent Skill that takes a coding agent through a whole A/B test: flag → metric →
experiment → traffic → verdict → rollout → cleanup PR → archive. A human approves every change
users can see. Then it was used to A/B test its own landing page.**

Built solo for [Toggle Wars: The Flagsmith Experimentation Hackathon](https://www.wemakedevs.org/hackathons/flagsmith)
(Nov 26–29, 2026).

- Live experiment: **https://faizydroid.github.io/prove-it-works/** (the headline is the test)
- The skill: [`skills/prove-it-works/`](skills/prove-it-works/)
- Demo video: _coming Sunday_
- Experiment write-up with the real numbers: [`docs/experiment.md`](docs/experiment.md) _(Sunday)_

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

```
$ bash scripts/results.sh --id 42 --refresh
{"ok":true,"experiment_id":42,"status":"running","flag":"landing_headline","as_of":"2026-11-28T18:05:11Z",
 "is_final":false,"srm_p_value":0.81,"srm_warning":false,
 "variants":{"control":{"n":312,"conversions":25,"rate":0.0801},
             "ai":{"n":305,"conversions":34,"rate":0.1115,"lift":0.392,"ci":[0.05,0.72],"chance_to_win":0.97}},
 "verdict":"winner","winner":"ai",
 "reason":"ai: 97% chance to beat control (+39% lift, 95% CI +5%..+72%)",
 "dashboard":"https://app.flagsmith.com/project/1/environment/ser.xxx/experiments/42"}
```

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
- Environments named like production get an extra, louder gate in `SKILL.md`.
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

The landing page in [`site/`](site/) is a real A/B test on real visitors, run with this skill.

- **Hypothesis:** an LLM-written headline beats the human-written one on CTA click-through by ≥20%.
- **Flag:** `landing_headline` (multivariate). Control = the human headline; variant `ai` = the
  LLM headline. The headline text *is* the flag value, so copy is remote config.
- **Metric:** `cta_click`, occurrence per identity: did this visitor click "Get the skill" at least once.
- **Traffic:** `production` environment gets real visitors from the hackathon Discord and social.
  `development` gets scripted identities from `simulate-traffic.mjs` as the fallback and the demo.
- **Result:** see [`docs/experiment.md`](docs/experiment.md) on Sunday, with lift, credible interval,
  win probability and what we did with it.

## Repo layout

```
skills/prove-it-works/     the skill: SKILL.md, scripts/, references/
site/                      the landing page under test (GitHub Pages)
docs/                      experiment write-up, demo-run transcript and token count
```

## License

MIT
