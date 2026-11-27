# prove-it-works

**An Agent Skill that takes a coding agent through a whole Flagsmith A/B test, and leaves no flag
behind: flag → metric → experiment → code → traffic → verdict → rollout → cleanup PR → archive.
A human approves every change users can see.**

Built solo for [Toggle Wars: The Flagsmith Experimentation Hackathon](https://www.wemakedevs.org/hackathons/flagsmith),
Nov 26–29, 2026.

- **See it work:** Claude Code ran the whole job on a demo app. 4 human messages, 2 merged PRs
  ([#1](https://github.com/faizydroid/prove-it-works-demo/pull/1),
  [#2](https://github.com/faizydroid/prove-it-works-demo/pull/2)), flag archived.
  Write-up and token count in [`docs/demo-run.md`](docs/demo-run.md).
- **See it on real users:** this skill's landing page, **https://faizydroid.github.io/prove-it-works/**,
  is itself a live A/B test. The hypothesis was registered before the first visitor:
  [`docs/experiment.md`](docs/experiment.md).
- **The skill:** [`skills/prove-it-works/`](skills/prove-it-works/). It passes the Agent Skills
  reference validator (`skills-ref validate`).
- **Demo video:** _link added on submission_

## The problem

Coding agents can already wire a feature flag in. The work that comes after is where teams
struggle: prove the change helped, ship the winner, delete the flag so the codebase doesn't rot.
Each of those is a chain of CLI calls, API payloads and judgement calls about statistics, and each
is a chance to touch production by accident. Flagsmith's own setup prompt stops once the experiment
is running; nobody had packaged the rest.

`prove-it-works` packages the whole job. The agent reads about 2,300 tokens of instructions and
runs six scripts that each return **one JSON line**. The scripts refuse unsafe moves even if the
agent asks for them.

## The job

| # | Step | Script | Human |
|---|---|---|---|
| 1 | Preflight: CLI, login, project, environment, warehouse | `preflight.sh` | |
| 2 | Design: what changes, what counts as success, a guardrail, the hypothesis | (conversation) | confirms the plan |
| 3 | Create the multivariate flag, keyed variants, metrics, experiment (at 0%: nothing served yet) | `create-experiment.sh` | approves |
| 4 | Instrument: exposure where the variation is seen, conversion where success happens; fail open | (code edits, PR) | reviews, merges |
| 5 | Start: rollout 0 → 100%, the flag locks | `start-experiment.sh` | approves |
| 6 | Traffic: real users, or scripted visitors with their rates printed in the output | `simulate-traffic.mjs` | never on production |
| 7 | Verdict: lift, 95% credible interval, win probability, sample-ratio check, guardrails | `results.sh` | |
| 8 | Roll out the winner (or keep control, or disable); rollback saved first | `rollout-winner.sh` | approves |
| 9 | Hardcode the winner, delete the losing branch and the flag reads, open the PR | (code edits, `gh`) | reviews, merges |
| 10 | Archive the flag, only once the PR is merged and nothing references it | `archive-flag.sh` | |

What the agent sees at step 7, from the demo run (simulated traffic, true rates 8% vs 14%):

```
$ bash .claude/skills/prove-it-works/scripts/results.sh --id 1364 --refresh
{"ok":true,"experiment_id":1364,"status":"running","flag":"pricing_default_billing","as_of":"2026-11-27T10:47:08.306618Z",
 "candidate":"annual","guardrails":[],"is_final":false,
 "reason":"annual: 100% chance to beat control (+53% lift, 95% CI +13%..+93%)",
 "srm_p_value":0.2301,"srm_source":"local","srm_warning":false,
 "variants":{"annual":{"chance_to_win":0.995,"ci":[0.125,0.927],"conversions":128,"lift":0.526,"n":824,"rate":0.1553},
             "control":{"conversions":79,"n":776,"rate":0.1018}},
 "verdict":"winner","winner":"annual","dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"}
```

That's the line exactly as the agent received it, wrapped for reading. The run exposed one bug:
`reason` rounded 0.995 to "100% chance". A probability shown as a certainty overstates the
evidence. `results.sh` now prints one decimal and never 100% ("99.5% chance").

At 600 visitors the same experiment read 96% with an interval of −6%…+135%. `results.sh` called
that `inconclusive`, because a credible interval that crosses zero isn't a win. The agent stopped
and asked instead of rolling out.

## Safety

Every one of these comes from something that went wrong, or nearly did, while building this.

- **The verdict decides, not the agent.** `rollout-winner.sh` re-reads the results and refuses to
  ship a variant unless it's the winner (≥ 95% chance **and** the interval above zero). It also
  refuses on a sample-ratio mismatch, while still collecting, or when a guardrail metric clearly
  dropped. The only override is `--override "<the human's exact words>"`, accepted for
  *inconclusive* or *guardrail* verdicts only, and written into the rollback file.
- **Rollback first.** The flag's state is saved to `.prove-it-works/rollback-*.json`, and the
  one-line rollback command is printed, before anything changes.
- **Production needs its name confirmed.** Write scripts refuse a production-like environment
  (Production, prod, live, prd) unless the agent passes `--confirm-env "<exact name>"` after the
  human approved it by name. They refuse any write whose confirmed name differs from the
  environment they resolved. During development a stray `FLAGSMITH_ENVIRONMENT` variable once sent
  a test at Production; this guard came out of that.
- **Nothing is served before the start.** Flagsmith applies an experiment's rollout as soon as
  it's created, so experiments are created at 0% and `start-experiment.sh` raises the rollout.
- **Archive, never delete, and only when it's truly gone.** `archive-flag.sh` needs the cleanup PR
  `MERGED`, no code reference left (`git grep`), and no unfinished experiment on the flag in *any*
  environment, because archiving is project-wide.
- **The app fails open.** Instrumentation must serve control if Flagsmith or the SDK can't load.
  The demo run's PR was reviewed for exactly this, and fixed.
- **Idempotent and honest about failure.** Re-running reuses the flag, variants, metrics and
  experiment instead of duplicating them. Network failures retry only when nothing was sent. Every
  error is `{"ok":false,"error":…,"hint":…}`, and the agent is told to show it to the human
  verbatim.

## Token count

From the demo run: Claude Code's `usage` field, summed over 4 turns and 47 model calls. Details are
in [`docs/demo-run.md`](docs/demo-run.md).

| Whole run | Tokens |
|---|---:|
| Fresh input (uncached + cache writes) | 166,452 |
| Cache reads | 1,012,026 |
| Output | 14,631 |
| **Total processed** | **1,193,109** (cost $3.08 at list price) |

| What the skill itself added to the context | ≈ Tokens |
|---|---:|
| `SKILL.md`, loaded once | 2,265 |
| `references/instrumentation.md`, read on demand | 1,363 |
| All 9 script outputs together | 941 |

The rest is the agent's own system prompt (about 19k tokens, re-read from cache on every call), the
app's files and git/gh output. Where the agent would otherwise read raw CLI output, a script
returns one line: preflight 3,465 → 397 characters, results 1,829 → 626 with the verdict included.

## Quickstart

You need: [Flagsmith CLI v2](https://docs.flagsmith.com/integrating-with-flagsmith/CLI), bash
(Git Bash on Windows), git, and `gh` for the PR steps. Node 18+ is only needed for simulated
traffic. Works with Flagsmith Cloud and self-hosted.

```bash
# 1. CLI + login (Windows: irm https://raw.githubusercontent.com/Flagsmith/flagsmith-cli/main/install.ps1 | iex)
curl -fsSL https://get.flagsmith.com | sh
flagsmith login

# 2. In your app's repo: bind it to a project and a NON-production environment to start with
flagsmith init --project <project> --environment <client-side environment key>

# 3. Install the skill where your agent looks for skills
git clone https://github.com/faizydroid/prove-it-works /tmp/piw
mkdir -p .claude/skills && cp -r /tmp/piw/skills/prove-it-works .claude/skills/   # Kiro: .kiro/skills/
npm install --prefix .claude/skills/prove-it-works/scripts                          # simulated traffic only

# 4. Check it can see everything (read-only)
bash .claude/skills/prove-it-works/scripts/preflight.sh
```

When it works, preflight prints one line like
`{"ok":true,"cli":"v2.0.0",…,"environment":{"name":"Development",…,"production_like":false},"warehouse":{"status":"created",…}}`.
Then start your agent (`claude`) and ask in plain words:

> A/B test whether the checkout button saying "Buy now" instead of "Checkout" gets more purchases.
> We're in Development: once it's running, simulate 1,000 visitors.

Environment variables (all optional):

| Variable | Effect |
|---|---|
| `FLAGSMITH_API_KEY` | Organisation Master API key, for CI or anywhere `flagsmith login` can't run |
| `FLAGSMITH_ENVIRONMENT` | Overrides `flagsmith.json`'s environment. Results report `"source":"env"`; production still needs `--confirm-env` |
| `FLAGSMITH_API_URL` | Self-hosted API, e.g. `https://flagsmith.example.com/api/v1/` |
| `PIW_STATE_DIR` | Where rollback files go (default `.prove-it-works/`; gitignore it) |
| `PIW_DASHBOARD` | Dashboard base URL for links, if self-hosted and not on the API host |

Without an agent, the scripts work on their own too; each one's header comment has its usage
and output.

## The experiment this repo ran on itself

The landing page in [`site/`](site/) is a live A/B test on real visitors, set up with these
scripts. The plan and decision rule were committed before the first visitor; results are added
Sunday, Nov 29, 2026 ([`docs/experiment.md`](docs/experiment.md)).

- **Hypothesis:** opening with the reader's problem ("Stop guessing which version wins. Let your
  agent prove it.") beats describing the product ("Run A/B tests from your coding agent.") on
  clicks to the GitHub repo, by at least 20% relative.
- **Flag:** `landing_headline`, multivariate. The headline text *is* the flag value.
- **Metric:** `cta_click`, occurrence per visitor. **Guardrail:** `example_viewed`, should not drop.
- **Clean data:** our own browsers are excluded with `?internal`. Simulated traffic goes only to
  Development, which has its own experiment. The run log records every change, with times.
- **Honest power:** a few hundred visitors can only detect a large effect (about 2×). If the
  interval still crosses zero on Sunday, the result is reported as inconclusive.

## Repo layout

```
skills/prove-it-works/   the skill: SKILL.md, scripts/ (6 bash scripts + simulator), references/
site/                    the landing page under test (deployed from the gh-pages branch)
docs/                    experiment.md, demo-run.md, demo-run-transcript.md, video-script.md
```

Deploy the site after editing `site/`: `git subtree split --prefix site -b gh-pages && git push origin gh-pages`.

## License

MIT
