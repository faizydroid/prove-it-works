# Demo video script (target 2:30)

The organisers' guide: two to three minutes; about fifteen seconds on the problem, most of the
time on the thing working, a clear look at the Flagsmith side, and the human approval shown
happening. Record Saturday, not Sunday.

**A complete draft already exists** (local only, gitignored): `video/prove-it-works-demo-draft.mp4`,
2:59, 1080p, with an offline Windows voice. It has 15 scenes, built from the real outputs of the
recorded run, the real PR diffs and real refusals, plus screenshots of both live headlines. Its
scene images are next to it in `video/`. Two upgrades would make it stronger:
1. **Your voice.** Record the 15 lines under *Draft narration* at the end of this file, one take per line, with any phone or headset mic. Name the files `01.m4a`…`15.m4a` and they replace the synthetic voice scene for scene.
2. **The real Flagsmith dashboard.** Swap scene 12's table for a screenshot of experiment 1364's
   results page, and scene 14's caption for a screenshot of experiment 715.

The shot list below is for recording it live instead.

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
   (simulated events take about a minute to land) to 4â€“8Ã— in editing.

---

## 0:00â€“0:15 Â· The problem

**Screen:** a slide or the README top: *flag â†’ metric â†’ experiment â†’ code â†’ traffic â†’ verdict â†’
rollout â†’ cleanup PR â†’ archive*.

> Coding agents can add a feature flag. But nobody makes them prove the change worked, ship the
> winner, and delete the flag afterwards. That last mile is where flag debt and production
> accidents come from.

## 0:15â€“0:30 Â· What it is

**Screen:** `skills/prove-it-works/` in the editor: `SKILL.md`, then the `scripts/` folder.

> prove-it-works is an Agent Skill for that whole job. One instruction file and six small scripts
> on the Flagsmith CLI. Each script hands the agent one line of JSON, and the scripts refuse
> unsafe moves even if the agent asks for them.

## 0:30â€“1:40 Â· The agent does the job (the main part)

**Screen:** Claude Code in `prove-it-works-demo`. Paste:

> Use Flagsmith to A/B test whether opening the pricing page on annual billing, instead of
> monthly, gets more visitors to start checkout. Use the flag name pricing_billing_video. We're in
> the Development environment, so once it's running, simulate about 600 visitors: monthly-first
> converts at 8%, annual-first at 14%.

Show, sped up, with short captions:

1. `preflight.sh` â†’ one JSON line. *Caption: read-only check*
2. `create-experiment.sh` â†’ flag, metric, experiment created at 0%.
3. The code edit and the PR it opens. Open the PR diff in the browser for two seconds.
4. `start-experiment.sh`, `simulate-traffic.mjs` (*Caption: simulated traffic, rates 8% vs 14%*).
5. **Key moment:** `results.sh` comes back *inconclusive* (if it does at 600) and the agent
   **stops and asks**. Pause here.

> Ninety-six percent sounds like a win. But the interval still crosses zero, so the skill calls it
> inconclusive, and the agent stops and asks me instead of shipping.

6. Type: *"Simulate 1,000 more, then read it once."* â†’ `winner`.
7. **The gate:** the agent asks to roll out. Type *"yes, roll out annual"*.
   Show `rollout-winner.sh` output and point at the `rollback` command.
8. The cleanup PR: the diff deletes every Flagsmith line. Merge it in the browser.
9. *"PR merged, archive the flag."* â†’ `archive-flag.sh` â†’ `archived: true`.

> Four messages from me, two pull requests, and the flag is gone.

## 1:40â€“1:55 Â· The Flagsmith side

**Screen:** experiment 1364 in the Flagsmith dashboard: exposures, win probability, lift,
credible interval, then the completed status and the archived flag.

> Flagsmith's Bayesian engine is the judge. The skill reads the same numbers, uses the same
> thresholds as this page, and adds the sample-ratio check that Flagsmith's beta skips for
> experiments created this way.

## 1:55â€“2:10 Â· Safety, live

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

## 2:10â€“2:25 Â· And on real users

**Screen:** the landing page (both headlines, reload in a private window), then experiment 715
in the dashboard.

> The skill's own landing page is a live A/B test on real visitors: problem-led versus product-led
> headline. The hypothesis and decision rule were committed before the first visitor, and if the
> interval still crosses zero on Sunday, I'll say so.

*(If you record after reading the results on Sunday, replace this line with the actual result.)*

## 2:25â€“2:35 Â· Close

**Screen:** README token table, then the repo URL.

> The whole job took about 1.2 million tokens of agent context, and the skill itself added under
> 5,000 of them. github.com/faizydroid/prove-it-works.

---

**Word count:** about 330 spoken words, which is 2:30 at a calm pace. If you'd rather not narrate,
the same text can be turned into a voice-over track. Ask before you record.

---

## Draft narration (matches the draft video, scene by scene)

1. **problem** (12 s): Coding agents can add a feature flag. But nobody makes them prove the change worked, ship the winner, and delete the flag afterwards. That last mile is where flag debt and production accidents come from.
2. **what** (15 s): prove-it-works is an Agent Skill for that whole job. One instruction file, and six small scripts on the Flagsmith CLI. Each script hands the agent a single line of JSON, and the scripts refuse unsafe moves, even if the agent asks for them.
3. **ask** (11 s): Here's Claude Code in a small pricing page that has never used Flagsmith. I ask for one thing, in plain words: does opening on annual billing get more people to start checkout?
4. **create** (11 s): The agent loads the skill, checks the setup, and creates the flag, the metric and the experiment. The experiment is created at zero percent, so nobody sees anything yet.
5. **pr1** (12 s): Then it edits the code. The Flagsmith SDK, the experiment flag where the page picks its billing period, and a conversion event on checkout. And it opens a pull request for me to review.
6. **inconclusive** (16 s): It starts the experiment, and sends six hundred simulated visitors. Ninety-six percent sounds like a win. But the credible interval still crosses zero. So the skill calls it inconclusive, and the agent stops and asks me, instead of shipping.
7. **review** (10 s): I review the pull request. If Flagsmith is down, the page must still work. The agent fixes that, and I ask for the larger sample we should have planned.
8. **winner** (10 s): At sixteen hundred visitors, annual converts at fifteen and a half percent, against ten. The interval is now above zero. That is a winner.
9. **gate** (12 s): Rolling out changes what users see, so the agent asks first. I say yes. The script saves the old state, and prints a one-line rollback, before it changes anything.
10. **pr2** (8 s): Then the cleanup. A second pull request hardcodes the winner, and deletes every Flagsmith line. I merge it.
11. **archive** (11 s): Only after that merge, with no code left reading the flag, is the flag archived. Four messages from me. Two pull requests. No flag debt.
12. **flagsmith** (13 s): Flagsmith Experimentation is the judge here. The skill reads the same Bayesian results, with the same thresholds as the dashboard, and adds the sample-ratio check that the beta skips for experiments set up this way.
13. **safety** (14 s): The safety rules live in the scripts, not in the prompt. Production needs its name confirmed. Nothing ships without evidence. And a flag cannot be archived while an experiment still uses it, in any environment.
14. **real** (12 s): And the skill's own landing page is a live A/B test on real visitors. A problem-led headline, against a product-led one. The hypothesis and the decision rule were committed before the first visitor.
15. **close** (13 s): The whole job took about one point two million tokens of agent context. The skill itself added under five thousand of them. It is open source, on GitHub: faizydroid, slash, prove-it-works.
