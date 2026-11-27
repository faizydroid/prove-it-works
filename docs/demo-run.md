# Demo run: Claude Code runs the whole job

**What this shows:** a coding agent that had never seen the app took a one-sentence request to an
archived flag. Along the way it changed the code, opened two real pull requests, read Flagsmith's
verdict and rolled out the winner. A human typed four messages and merged two PRs. Nothing else
was done by hand.

| | |
|---|---|
| Agent | Claude Code 2.1.263, model `claude-fable-5-1`, user's default permission mode, `gh pr merge` and `gh api` denied |
| App | [`faizydroid/prove-it-works-demo`](https://github.com/faizydroid/prove-it-works-demo), a static pricing page with no Flagsmith code |
| Skill | `prove-it-works`, vendored at `.claude/skills/prove-it-works/` |
| Flagsmith | Cloud, project `toggle-wars`, **Development** environment, [experiment 1364](https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364) |
| Traffic | **Simulated**: 1,600 scripted visitors, true checkout rates set to 8% (monthly-first) and 14% (annual-first) |
| Date | Nov 27, 2026, about 14 minutes of agent time across 4 turns |
| Transcript | [demo-run-transcript.md](demo-run-transcript.md) (condensed, from the `stream-json` log) |

## The four human messages

1. "Use Flagsmith to A/B test whether opening the pricing page on annual billing, instead of
   monthly, gets more visitors to start checkout. We're in the Development environment, so once
   it's running, simulate about 600 visitors: monthly-first converts at 8%, annual-first at 14%."
2. A code review note on PR #1: "if Flagsmith is unreachable, `await flagsmith.init` throws and the
   pricing page never renders at all. Make the page fall back to monthly…". It also said the sample
   had been planned too small: simulate 1,000 more, then read the results once.
3. "I merged PR #1. Yes: roll out annual in Development, then open the cleanup PR."
4. "PR #2 is merged. Archive the flag."

## What the agent did

| Step | Skill step | What happened |
|---|---|---|
| Preflight | 1 | `preflight.sh`: CLI v2, logged in, `toggle-wars` / Development, warehouse present |
| Design | 2 | Read the 7 app files, found the existing anonymous id in `user.js` and the checkout click in `app.js` |
| Create | 3 | `create-experiment.sh`: flag `pricing_default_billing` (control `monthly`, variant `annual`), metric `checkout_started`, experiment 1364 at 0% |
| Instrument | 4 | Added the JS SDK, `getExperimentFlag` where the page picks its billing period, `trackEvent` on checkout. Opened [PR #1](https://github.com/faizydroid/prove-it-works-demo/pull/1) |
| Start + traffic | 5, 6 | `start-experiment.sh` (rollout 0 → 100%), `simulate-traffic.mjs` with 600 visitors |
| Verdict | 7 | `results.sh`: **inconclusive**. 96% chance annual is better, but the 95% interval was −6%…+135%, so it **refused to call a winner** and stopped to ask |
| Review fix | 4 | Made the page fail open (dynamic import + try/catch, tracking never blocks checkout) and pushed to PR #1 |
| More traffic, verdict | 6, 7 | 1,000 more visitors, one read: **winner `annual`**, 15.5% vs 10.2%, +53% lift, 95% interval +12.5%…+92.7%, 99.5% chance to win, split check passed (p = 0.23) |
| Roll out | 8 | Asked first, then `rollout-winner.sh --variant annual`: experiment completed, annual at 100%, rollback command saved |
| Clean up | 9 | Hardcoded annual and removed every Flagsmith line, which returned `app.js` to its original shape. Opened [PR #2](https://github.com/faizydroid/prove-it-works-demo/pull/2) |
| Archive | 10 | After the merge: `archive-flag.sh --pr 2` checked that the PR was merged and no code still referenced the flag, then archived it |

Checked independently afterwards:
- the experiment is `completed` with decision `variant`, and the flag `is_archived: true`;
- a fresh identity evaluates to `annual`;
- `git grep pricing_default_billing` on `main` finds nothing outside the vendored skill.

The PR #1 code was also checked in headless Edge: with every Flagsmith and CDN request blocked,
the page still renders on monthly and checkout still works.

Message 2 extended the sample after one look at the results. With real traffic that's optional
stopping, which the skill warns against: checking until a number looks good turns noise into a
"winner". Here the true rates were set by the simulator (8% vs 14%), so there was no noise to
promote. The extension is only there to show both verdicts, `inconclusive` and then `winner`.

The agent decided two things on its own, and both are now written into the skill. In turn 1 it
treated "once it's running, simulate…" as approval for steps 3 to 6 in Development, but stopped
before any rollout. It also didn't wait for PR #1 to merge before starting, because simulated
traffic never runs the app. `SKILL.md` now spells out both rules, and neither applies to a
production-like environment.

## Token count

From Claude Code's own `usage` field, summed over the 4 turns (47 model calls):

| | Tokens |
|---|---:|
| Input, uncached | 746 |
| Input, written to cache | 165,706 |
| Input, read from cache | 1,012,026 |
| Output | 14,631 |
| **Total processed** | **1,193,109** |
| Cost at list price | $3.08 |

Cache reads dominate because every model call re-reads the conversation so far, including Claude
Code's own system prompt of about 19k tokens. That part comes from the agent, not the skill.

What the **skill** put into the context (characters divided by 4; approximate):

| Source | Characters | ≈ Tokens |
|---|---:|---:|
| `SKILL.md` body, loaded once | 9,058 | 2,265 |
| `references/instrumentation.md`, read on demand | 5,451 | 1,363 |
| All 9 script outputs together | 3,762 | 941 |
| Everything else the agent read: app files, git and gh output | 23,105 | 5,776 |

Each script returns one line where the agent would otherwise read raw CLI output. Measured on
the same experiment:

| Job | Raw CLI/API output | Script output |
|---|---:|---:|
| Preflight (auth, config, project, environment, warehouse) | 3,465 chars | 397 chars |
| Results (experiment + results payload) | 1,829 chars | 626 chars, verdict included |
| Idempotency lookups before creating (feature, metrics, experiments) | 8,236 chars | inside `create-experiment.sh`'s 415 |

The raw results payload grows as the experiment runs, because it carries hourly time series.
`results.sh` stays one line.

## Reproduce it

```
git clone https://github.com/faizydroid/prove-it-works-demo && cd prove-it-works-demo
git checkout 1daabb5 -- app.js        # the pre-experiment pricing page
flagsmith login                        # and `flagsmith init` against your own project
npm install --prefix .claude/skills/prove-it-works/scripts
claude                                 # then paste message 1 above, with a new flag name
```
