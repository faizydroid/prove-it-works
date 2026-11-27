# Demo video script (target 2:30)

The organisers' guide: two to three minutes; about fifteen seconds on the problem, most of the
time on the thing working, a clear look at the Flagsmith side, and the human approval shown
happening. Record Saturday, not Sunday.

**Setup before recording (10 minutes)**

1. Screen recorder: OBS Studio, or Windows Game Bar (`Win+Alt+R`). 1080p, terminal font 18pt or
   larger, notifications off.
2. Browser tabs, logged in to Flagsmith:
   - experiment 1364: https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364
   - experiment 715: https://app.flagsmith.com/project/56671/environment/hBLGZrbouE5zkSp7dYgWjG/experiments/715
   - PR #1 and PR #2: https://github.com/faizydroid/prove-it-works-demo/pulls?q=is%3Apr
   - the landing page, opened with `?internal` first: https://faizydroid.github.io/prove-it-works/?internal
3. For the live agent segment, reset the demo app to its pre-experiment state:
   ```
   cd prove-it-works-demo && git pull
   git checkout 1daabb5 -- app.js && git commit -qm "Reset pricing page for the video run" && git push
   ```
   Use a **new flag name** in the prompt (`pricing_billing_video`). The old flag is archived, and
   the skill refuses to reuse an archived name.
4. Run the agent once before recording. Then record a second run, and speed up the waiting parts
   (simulated events take about a minute to land) to 4–8× in editing.

---

## 0:00–0:15 · The problem

**Screen:** a slide or the README top: *flag → metric → experiment → code → traffic → verdict →
rollout → cleanup PR → archive*.

> Coding agents can add a feature flag. But nobody makes them prove the change worked, ship the
> winner, and delete the flag afterwards. That last mile is where flag debt and production
> accidents come from.

## 0:15–0:30 · What it is

**Screen:** `skills/prove-it-works/` in the editor: `SKILL.md`, then the `scripts/` folder.

> prove-it-works is an Agent Skill for that whole job. One instruction file and six small scripts
> on the Flagsmith CLI. Each script hands the agent one line of JSON, and the scripts refuse
> unsafe moves even if the agent asks for them.

## 0:30–1:40 · The agent does the job (the main part)

**Screen:** Claude Code in `prove-it-works-demo`. Paste:

> Use Flagsmith to A/B test whether opening the pricing page on annual billing, instead of
> monthly, gets more visitors to start checkout. Use the flag name pricing_billing_video. We're in
> the Development environment, so once it's running, simulate about 600 visitors: monthly-first
> converts at 8%, annual-first at 14%.

Show, sped up, with short captions:

1. `preflight.sh` → one JSON line. *Caption: read-only check*
2. `create-experiment.sh` → flag, metric, experiment created at 0%.
3. The code edit and the PR it opens. Open the PR diff in the browser for two seconds.
4. `start-experiment.sh`, `simulate-traffic.mjs` (*Caption: simulated traffic, rates 8% vs 14%*).
5. **Key moment:** `results.sh` comes back *inconclusive* (if it does at 600) and the agent
   **stops and asks**. Pause here.

> Ninety-six percent sounds like a win. But the interval still crosses zero, so the skill calls it
> inconclusive, and the agent stops and asks me instead of shipping.

6. Type: *"Simulate 1,000 more, then read it once."* → `winner`.
7. **The gate:** the agent asks to roll out. Type *"yes, roll out annual"*.
   Show `rollout-winner.sh` output and point at the `rollback` command.
8. The cleanup PR: the diff deletes every Flagsmith line. Merge it in the browser.
9. *"PR merged, archive the flag."* → `archive-flag.sh` → `archived: true`.

> Four messages from me, two pull requests, and the flag is gone.

## 1:40–1:55 · The Flagsmith side

**Screen:** experiment 1364 in the Flagsmith dashboard: exposures, win probability, lift,
credible interval, then the completed status and the archived flag.

> Flagsmith's Bayesian engine is the judge. The skill reads the same numbers, uses the same
> thresholds as this page, and adds the sample-ratio check that Flagsmith's beta skips for
> experiments created this way.

## 1:55–2:10 · Safety, live

**Screen:** terminal. Run three commands that get refused (output is one red line each):

```
FLAGSMITH_ENVIRONMENT=hBLGZrbouE5zkSp7dYgWjG bash .claude/skills/prove-it-works/scripts/create-experiment.sh --flag x --control a --variant b=b --event e --name n --hypothesis h
bash .claude/skills/prove-it-works/scripts/rollout-winner.sh --id 714 --variant problem
bash .claude/skills/prove-it-works/scripts/archive-flag.sh --flag landing_headline --no-pr
```

Expected refusals, in order:
- *"'Production' looks like production and was not confirmed"*
- *"not enough data yet"* (714 is the Development twin of the landing-page test, with no traffic)
- *"unfinished experiment(s) still use 'landing_headline' in: Development (1), Production (1)"*

> Production needs its name confirmed. Nothing ships without evidence. A flag can't be archived
> while code still reads it or an experiment still runs, in any environment.

## 2:10–2:25 · And on real users

**Screen:** the landing page (both headlines, reload in a private window), then experiment 715
in the dashboard.

> The skill's own landing page is a live A/B test on real visitors: problem-led versus product-led
> headline. The hypothesis and decision rule were committed before the first visitor, and if the
> interval still crosses zero on Sunday, I'll say so.

*(If you record after reading the results on Sunday, replace this line with the actual result.)*

## 2:25–2:35 · Close

**Screen:** README token table, then the repo URL.

> The whole job took about 1.2 million tokens of agent context, and the skill itself added under
> 5,000 of them. github.com/faizydroid/prove-it-works.

---

**Word count:** about 330 spoken words, which is 2:30 at a calm pace. If you'd rather not narrate,
the same text can be turned into a voice-over track. Ask before you record.
