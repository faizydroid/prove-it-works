# Recorded run transcript (condensed)

Claude Code 2.1.263 in [`faizydroid/prove-it-works-demo`](https://github.com/faizydroid/prove-it-works-demo), Nov 27, 2026. Tool results are trimmed; file reads are shown as sizes; the account email is redacted. Summary and token count: [demo-run.md](demo-run.md).

## Turn 1

**Human:** Use Flagsmith to A/B test whether opening the pricing page on annual billing, instead of monthly, gets more visitors to start checkout. We're in the Development environment, so once it's running, simulate about 600 visitors: monthly-first converts at 8%, annual-first at 14%.

**Agent:** I'll load the Flagsmith A/B testing skill and then run the experiment end to end.

```text
> Skill: prove-it-works
```
```text
(31 chars)
```
**Agent:** Starting with preflight and a look at the repo.

```text
> PowerShell: bash .claude/skills/prove-it-works/scripts/preflight.sh
```
```text
> Glob: **/*
```
```text
{"ok":true,"cli":"v2.0.0","user":"<redacted-email>","project":{"id":56671,"name":"toggle-wars"},"environment":{"key":"dMF4K5LSSqPndCs8DprMKJ","name":"Development","source":"config","production_like":false},"warehouse":{"detail":null,"event_names":6,"events":1666,"status":"created","type":"flagsmith"},"dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ"}
```
```text
(5654 chars)
```
**Agent:** Preflight passed: project toggle-wars, Development environment, warehouse created. Now reading the app code and the instrumentation reference.

```text
> Read: D:\Apps\flag\demo\index.html
```
```text
(1956 chars)
```
```text
> Read: D:\Apps\flag\demo\app.js
```
```text
> Read: D:\Apps\flag\demo\prices.js
```
```text
(1302 chars)
```
```text
(191 chars)
```
```text
> Read: D:\Apps\flag\demo\user.js
```
```text
(350 chars)
```
```text
> Read: D:\Apps\flag\demo\checkout.html
```
```text
(668 chars)
```
```text
> Read: D:\Apps\flag\demo\README.md
```
```text
(789 chars)
```
```text
> Read: D:\Apps\flag\demo\flagsmith.json
```
```text
(181 chars)
```
```text
> Read: D:\Apps\flag\demo\.claude\skills\prove-it-works\references\instrumentation.md
```
```text
(5451 chars)
```
**Agent:** Preflight is green. I'm proceeding on the user's explicit instruction to set up, start, and simulate in Development. Creating the experiment now and checking the git/tooling setup.

```text
> PowerShell: bash .claude/skills/prove-it-works/scripts/create-experiment.sh --flag pricing_default_billing --control "monthly" --variant annual="annual" --event checkout_started --name "Pricing page: annual-first billing default" --hypothesis "Opening the pricing page on annual billing (lower monthly-equivalent price shown) instead of monthly will raise the share of visitors who start checkout from about 8% to about 14% over a run of roughly 600 visitors."
```
```text
> PowerShell: git remote -v; git branch --show-current; (Get-Command gh -ErrorAction SilentlyContinue).Source; (Get-Command node).Source; node --version; Test-Path .claude/skills/prove-it-works/scripts/node_modules/@flagsmith/flagsmith/package.json
```
```text
{"ok":true,"flag":"pricing_default_billing","feature_id":307022,"variants":{"annual":38166},"metric_id":1412,"guardrails":{},"experiment_id":1364,"status":"created","reused":{"flag":false,"metric":false,"experiment":false},"environment":{"name":"Development","key":"dMF4K5LSSqPndCs8DprMKJ","source":"config"},"dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"}
```
```text
origin	https://github.com/faizydroid/prove-it-works-demo.git (fetch)
origin	https://github.com/faizydroid/prove-it-works-demo.git (push)
main
C:\Program Files\GitHub CLI\gh.exe
G:\Program Files\nodejs\node.exe
v24.16.0
True
```
**Agent:** Experiment 1364 is created at 0% rollout. Next I'll instrument app.js, commit on a branch, and open the PR.

```text
> Write D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
```text
> Grep: getExperimentFlag|"version"
```
```text
.claude\skills\prove-it-works\scripts\node_modules\@flagsmith\flagsmith\package.json:3:  "version": "12.6.0",
.claude\skills\prove-it-works\scripts\node_modules\@flagsmith\flagsmith\types.d.ts:148:     * started and trackEvent / trackExposureEvent / getExperimentFlag become
.claude\skills\prove-it-works\scripts\node_modules\@flagsmith\flagsmith\types.d.ts:348:    getExperimentFlag: (featureName: string) => IFlagsmithFeature | null;
.claude\skills\prove-it-works\scripts\node_modules\@flagsmith\flagsmith\src\types.d.ts:148:     * started and trackEvent / trackExposureEvent / getExperimentFlag become
.claude\skills\prove-it-works\scripts\node_modules\@flagsmith\flagsmith\src\types.d.ts:348:    getExperimentFlag: (featureName: string) => IFlagsmithFeature | null;
```
```text
> PowerShell: git switch -c exp/pricing_default_billing; git add app.js; git commit -q -m "Experiment pricing_default_billing: annual-first vs monthly-first pricing default" -m "Opening the pricing page on annual billing instead of monthly should raise the share of visitors who start checkout. Experiment: https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"; git log --oneline -1
```
```text
Switched to a new branch 'exp/pricing_default_billing'
2c0b06d Experiment pricing_default_billing: annual-first vs monthly-first pricing default
```
**Agent:** Committed. Pushing the branch and opening the PR, and starting the experiment in Development in parallel.

```text
> PowerShell: git push -u origin exp/pricing_default_billing; gh pr create --title "Experiment pricing_default_billing: open pricing page on annual billing" --body "Opening the pricing page on annual billing (lower monthly-equivalent price shown) instead of monthly will raise the share of visitors who start checkout from about 8% to about 14% over a run of roughly 600 visitors. Experiment: https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"
```
```text
> PowerShell: bash .claude/skills/prove-it-works/scripts/start-experiment.sh --id 1364 --rollout 100
```
```text
remote: 
remote: Create a pull request for 'exp/pricing_default_billing' on GitHub by visiting:        
remote:      https://github.com/faizydroid/prove-it-works-demo/pull/new/exp/pricing_default_billing        
remote: 
branch 'exp/pricing_default_billing' set up to track 'origin/exp/pricing_default_billing'.
To https://github.com/faizydroid/prove-it-works-demo.git
 * [new branch]      exp/pricing_default_billing -> exp/pricing_default_billing
https://github.com/faizydroid/prove-it-works-demo/pull/1
```
```text
{"ok":true,"experiment_id":1364,"status":"running","rollout":100,"started_at":"2026-11-27T10:32:06.621081Z","flag":"pricing_default_billing","environment":{"name":"Development","key":"dMF4K5LSSqPndCs8DprMKJ","source":"config"},"dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"}
```
**Agent:** PR #1 is open and experiment 1364 is running at 100% in Development. Now simulating 600 visitors.

```text
> PowerShell: node .claude/skills/prove-it-works/scripts/simulate-traffic.mjs --env dMF4K5LSSqPndCs8DprMKJ --flag pricing_default_billing --event checkout_started --users 600 --rates control=0.08,annual=0.14
```
```text
{"ok":true,"users":600,"in_experiment":600,"outside":0,"exposed":{"annual":310,"control":290},"converted":{"annual":51,"control":29},"rates_used":{"control":0.08,"annual":0.14},"seed":1,"identity_prefix":"sim-1-","note":"Events can take a minute to land; results.sh --refresh is allowed every 5 minutes."}
```
**Agent:** Simulation done: 600 visitors, 290 control / 310 annual. Waiting about a minute for events to land, then pulling results.

```text
> PowerShell: Start-Sleep -Seconds 75; bash .claude/skills/prove-it-works/scripts/results.sh --id 1364 --refresh
```
```text
{"ok":true,"experiment_id":1364,"status":"running","flag":"pricing_default_billing","as_of":"2026-11-27T10:34:58.346523Z","candidate":"annual","guardrails":[],"is_final":false,"reason":"annual: 96% chance to beat control (+65% lift, 95% CI -6%..+135%)","srm_p_value":0.4142,"srm_source":"local","srm_warning":false,"variants":{"annual":{"chance_to_win":0.964,"ci":[-0.058,1.348],"conversions":51,"lift":0.645,"n":310,"rate":0.1645},"control":{"conversions":29,"n":290,"rate":0.1}},"verdict":"inconclusive","winner":null,"dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"}
```
**Agent:** Experiment is live and the first read is in. The planned check is done, so I'm stopping before any rollout decision.

**Outcome:** the annual-first variant looks better but the result is **inconclusive** at 600 simulated visitors. The 95% interval still spans zero, so Flagsmith does not name a winner yet.

Simulated results (Development environment, experiment 1364, seeded traffic with rates control=0.08, annual=0.14):

| Variant | Visitors | Checkouts started | Rate | Lift | 95% interval | Chance to win |
|---|---|---|---|---|---|---|
| control (monthly) | 290 | 29 | 10.0% | | | |
| annual | 310 | 51 | 16.5% | +65% | -6% .. +135% | 96% |

The split passed the sample-ratio check, and these numbers are simulated, not real visitors.

What I did:
- **Preflight** passed against project toggle-wars, Development, with the managed warehouse already created.
- **Created** flag `pricing_default_billing` with control `monthly` and variant `annual`, metric on event `checkout_started`, and experiment 1364. No guardrail was set since this page has no second natural event to protect.
- **Instrumented** the pricing page in app.js: Flagsmith JS SDK 12.6.0 from the CDN, identified by the existing anonymous id, exposure recorded via the experiment-flag call, conversion tracked and flushed on the checkout click. Pushed as [PR #1](https://github.com/faizydroid/prove-it-works-demo/pull/1).
- **Started** the experiment at 100% rollout and ran the 600-visitor simulation.

Dashboard: https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364

Your call on next steps. Options are to simulate more visitors so the interval tightens, to stop and keep control, or to ship annual with an explicit override since the verdict is inconclusive. I did not merge PR #1, roll anything out, or touch the flag beyond starting the experiment.


_Turn 1: 22 model turns, 331 s, $0.90._


## Turn 2

**Human:** Review note on PR #1 before I merge it: if Flagsmith is unreachable, `await flagsmith.init` throws and the pricing page never renders at all. Make the page fall back to monthly in that case and push the fix to the same PR. After that: we planned too small a sample. The new plan is 1,600 visitors in total, so simulate 1,000 more with the same rates, then read the results once.

**Agent:** Fixing the init failure path first, then the simulation.

```text
> Grep: seed|prefix|--[a-z-]+
```
```text
6://   npm install --prefix scripts            # once: installs @flagsmith/flagsmith next to this file
7://   node scripts/simulate-traffic.mjs --env <client-side key> --flag landing_headline \
8://        --event cta_click --users 400 --rates control=0.08,ai=0.11 [--seed 1] \
9://        [--guardrail-event example_viewed --guardrail-rates control=0.6,ai=0.6] \
10://        [--api https://flagsmith.example.com/api/v1/] [--events-url https://flagsmith.example.com/api/]
14://    "converted":{"control":16,"ai":23},"rates_used":{"control":0.08,"ai":0.11},"seed":1,
15://    "identity_prefix":"sim-1-","note":"Results refresh is allowed every 5 minutes; events can take a minute to land."}
31:const seed = Number(args.seed ?? 1);
32:if (!env || !flagName || !event) die('Required: --env <client-side key> --flag <name> --event <event>');
33:if (!Number.isInteger(users) || users < 1 || users > 20000 …[1178 more chars]
```
**Agent:** Identities are keyed by seed, so the second batch needs `--seed 2` to produce new visitors rather than re-exposing the first 600. Now the code fix.

```text
> Edit D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
**Agent:** The static CDN import would also take the page down if jsdelivr is unreachable, so I'll load the SDK inside the same try block to make the fallback complete.

```text
> Edit D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
```text
> Edit D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
```text
> Edit D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
```text
> Edit D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
```text
> Edit D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
```text
> Read: D:\Apps\flag\demo\app.js
```
```text
(2666 chars)
```
```text
> PowerShell: git status --short; git branch --show-current; node --check app.js; if ($?) { "syntax ok" }
```
```text
M app.js
exp/pricing_default_billing
syntax ok
```
```text
> Grep: flushEvents|trackEvent:
```
```text
320:    trackEvent: (event: string, opts?: {
354:    flushEvents: () => Promise<void>;
```
**Agent:** Both return the expected types. Committing and pushing the fix to PR #1, and kicking off the second simulation batch with a fresh seed so the identities are new.

```text
> PowerShell: git add app.js; git commit -q -m "pricing_default_billing: render monthly if the Flagsmith SDK or init fails" -m "Review note on PR #1: an unreachable Flagsmith made init throw and the page never rendered. The SDK is now loaded and initialised inside a try block; on failure the page falls back to monthly and event calls are skipped."; git push; git log --oneline -2
```
```text
> PowerShell: node .claude/skills/prove-it-works/scripts/simulate-traffic.mjs --env dMF4K5LSSqPndCs8DprMKJ --flag pricing_default_billing --event checkout_started --users 1000 --seed 2 --rates control=0.08,annual=0.14
```
```text
To https://github.com/faizydroid/prove-it-works-demo.git
   2c0b06d..6b297e0  exp/pricing_default_billing -> exp/pricing_default_billing
6b297e0 pricing_default_billing: render monthly if the Flagsmith SDK or init fails
2c0b06d Experiment pricing_default_billing: annual-first vs monthly-first pricing default
```
```text
{"ok":true,"users":1000,"in_experiment":1000,"outside":0,"exposed":{"annual":514,"control":486},"converted":{"annual":77,"control":50},"rates_used":{"control":0.08,"annual":0.14},"seed":2,"identity_prefix":"sim-2-","note":"Events can take a minute to land; results.sh --refresh is allowed every 5 minutes."}
```
**Agent:** Fix pushed and the second batch of 1,000 is in. Waiting for events to land, then taking the single planned read.

```text
> PowerShell: Start-Sleep -Seconds 90; bash .claude/skills/prove-it-works/scripts/results.sh --id 1364 --refresh
```
```text
{"ok":true,"experiment_id":1364,"status":"running","flag":"pricing_default_billing","as_of":"2026-11-27T10:47:08.306618Z","candidate":"annual","guardrails":[],"is_final":false,"reason":"annual: 100% chance to beat control (+53% lift, 95% CI +13%..+93%)","srm_p_value":0.2301,"srm_source":"local","srm_warning":false,"variants":{"annual":{"chance_to_win":0.995,"ci":[0.125,0.927],"conversions":128,"lift":0.526,"n":824,"rate":0.1553},"control":{"conversions":79,"n":776,"rate":0.1018}},"verdict":"winner","winner":"annual","dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"}
```
**Agent:** Both parts are done. The fix is on PR #1, and at 1,600 visitors Flagsmith names **annual the winner**.

**Fallback fix, pushed to PR #1** as commit `6b297e0` on the same branch. The SDK is now loaded with a dynamic import and initialised inside one try block. If the CDN or Flagsmith is unreachable, the page renders on monthly and logs a warning. Event tracking and flushing only run when the SDK came up, so the checkout button always navigates. I covered the CDN import as well as init, since a failed static import would also have blanked the page.

**Results, read once after the second batch** (Development, experiment 1364, simulated traffic with rates control=0.08, annual=0.14, seeds 1 and 2):

| Variant | Visitors | Checkouts started | Rate | Lift | 95% interval | Chance to win |
|---|---|---|---|---|---|---|
| control (monthly) | 776 | 79 | 10.2% | | | |
| annual | 824 | 128 | 15.5% | +53% | +13% .. +93% | 99.5% |

In plain words: annual-first converted 15.5% against 10.2% for monthly-first. The interval no longer spans zero, the sample-ratio check passed, and the verdict is `winner: annual`. These are simulated numbers, not real visitors.

Dashboard: https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364

The next step is a gate I need your yes on. Rolling out would complete experiment 1364 and make the Development environment serve `annual` to 100% of identities, freezing the results and unlocking the flag. After that I would open a second PR that hardcodes annual and removes the flag from app.js. Say "roll out annual" and I'll proceed, or tell me to hold.


_Turn 2: 14 model turns, 328 s, $0.89._


## Turn 3

**Human:** I merged PR #1. Yes: roll out annual in Development, then open the cleanup PR.

**Agent:** Rolling out annual in Development now, then opening the cleanup PR.

```text
> PowerShell: bash .claude/skills/prove-it-works/scripts/rollout-winner.sh --id 1364 --variant annual
```
```text
{"ok":true,"experiment_id":1364,"status":"completed","flag":"pricing_default_billing","decision":"variant","serving":"annual","verdict":"winner","override":"","rollback":"flagsmith flag update pricing_default_billing --weight annual=0","rollback_file":".prove-it-works/rollback-pricing_default_billing-20261127T105033Z.json","environment":{"name":"Development","key":"dMF4K5LSSqPndCs8DprMKJ","source":"config"},"dashboard":"https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"}
```
**Agent:** Rollout completed. Verifying the flag serves annual and syncing main for the cleanup branch.

```text
> PowerShell: flagsmith eval pricing_default_billing --identity verify-after-rollout-1 --json
```
```text
> PowerShell: git switch main; git pull -q; git log --oneline -3; git status --short; Test-Path .prove-it-works; Get-Content .gitignore
```
```text
{
  "name": "pricing_default_billing",
  "enabled": true,
  "value": "annual",
  "reason": "SPLIT; weight=100.0",
  "variant": "annual"
}
```
```text
Your branch is up to date with 'origin/main'.
Switched to branch 'main'
81d029f Merge PR #1: experiment pricing_default_billing (reviewed: fallback fix requested and applied)
6b297e0 pricing_default_billing: render monthly if the Flagsmith SDK or init fails
2c0b06d Experiment pricing_default_billing: annual-first vs monthly-first pricing default
True
node_modules/
.prove-it-works/
.claude/settings.local.json
```
**Agent:** The flag serves annual at 100%. The rollback file is already gitignored. Now hardcoding annual and removing the flag from the code.

```text
> Write D:\Apps\flag\demo\app.js
```
```text
<tool_use_error>File has been modified since read, either by the user or by a linter. Read it again before attempting to write it.</tool_use_error>
```
**Agent:** The file changed on disk when I switched to main, so I'll re-read it before writing.

```text
> Read: D:\Apps\flag\demo\app.js
```
```text
(2666 chars)
```
```text
> Write D:\Apps\flag\demo\app.js
```
```text
The file D:\Apps\flag\demo\app.js has been updated successfully. (file state is current in your context — no need to Read it back)
```
**Agent:** Checking syntax and remaining flag references, then branching and opening the PR.

```text
> PowerShell: node --check app.js; if ($?) { "syntax ok" }; git grep -n pricing_default_billing -- ':!.claude/skills' ; "grep exit: $LASTEXITCODE"; git diff --stat
```
```text
syntax ok
grep exit: 1
 app.js | 38 +++++---------------------------------
 1 file changed, 5 insertions(+), 33 deletions(-)
```
**Agent:** Syntax is clean and no code references the flag remain. Creating the cleanup branch and PR.

```text
> PowerShell: git switch -c chore/remove-pricing_default_billing; git commit -q -am "Remove pricing_default_billing: annual at 100% (experiment 1364)" -m "Annual-first won: 15.5% vs 10.2% of visitors started checkout (+53% lift, 95% CI +13%..+93%, 99.5% chance to win) on 1,600 simulated Development visitors. The pricing page now opens on annual for everyone; the Flagsmith SDK, experiment flag call and conversion tracking are removed. Experiment: https://app.flagsmith.com/project/56671/environment/dMF4K5LSSqPndCs8DprMKJ/experiments/1364"; git push -u origin chore/remove-pricing_default_billing; gh pr create --title "Remove pricing_default_billing: annual won (experiment 1364)" --body "Annual-fi …[555 more chars]
```
```text
Switched to a new branch 'chore/remove-pricing_default_billing'
remote: 
remote: Create a pull request for 'chore/remove-pricing_default_billing' on GitHub by visiting:        
remote:      https://github.com/faizydroid/prove-it-works-demo/pull/new/chore/remove-pricing_default_billing        
remote: 
branch 'chore/remove-pricing_default_billing' set up to track 'origin/chore/remove-pricing_default_billing'.
To https://github.com/faizydroid/prove-it-works-demo.git
 * [new branch]      chore/remove-pricing_default_billing -> chore/remove-pricing_default_billing
https://github.com/faizydroid/prove-it-works-demo/pull/2
```
**Agent:** Annual is rolled out in Development and the cleanup PR is open.

**Rollout, done.** Experiment 1364 is completed and the Development environment now serves `annual` to 100%. A fresh identity evaluated through the CLI gets annual. The script saved a rollback file under the gitignored `.prove-it-works/` folder. The one-line rollback, should you need it:

```
flagsmith flag update pricing_default_billing --weight annual=0
```

**Cleanup PR, open as [PR #2](https://github.com/faizydroid/prove-it-works-demo/pull/2).** It starts from the merged main and hardcodes annual as the default billing period. I removed the Flagsmith SDK import, the experiment flag call, and the checkout tracking, since the page had no analytics before the experiment and keeping only a tracking call would be flag debt by another name. The file is back to its original shape with the new default and the comment records the result. Syntax checks pass and `git grep` finds no remaining code reference to the flag outside the vendored skill.

**Next, after you merge PR #2:** run the archive step and I will do the last check.

```
bash .claude/skills/prove-it-works/scripts/archive-flag.sh --flag pricing_default_billing --pr 2
```

It refuses unless PR #2 is merged, so it has to wait for you. Tell me when it's merged and I'll archive the flag.


_Turn 3: 9 model turns, 149 s, $0.75._


## Turn 4

**Human:** PR #2 is merged. Archive the flag.

**Agent:** Archiving the flag now.

```text
> PowerShell: git switch main; git pull -q; git log --oneline -1; bash .claude/skills/prove-it-works/scripts/archive-flag.sh --flag pricing_default_billing --pr 2
```
```text
Your branch is up to date with 'origin/main'.
Already on 'main'
86e38a5 Merge PR #2: remove pricing_default_billing, annual won
{"ok":true,"flag":"pricing_default_billing","archived":true,"pr":2,"pr_state":"MERGED","code_references":0}
```
**Agent:** The flag is archived. The experiment is finished end to end with no flag debt left behind.

**Archive, done.** The script confirmed PR #2 is merged, found no code references to `pricing_default_billing`, and archived the flag project-wide. Experiment 1364 and its results stay visible in the dashboard history.

Where things stand:

- **Code:** main is at the merge of PR #2. The pricing page opens on annual for everyone with no Flagsmith SDK in the app.
- **Flagsmith:** flag archived, experiment 1364 completed with annual as the decision in Development.
- **Record:** PR #1 added the experiment with the fallback fix, PR #2 removed the flag. Both cite the dashboard link.

Result for the write-up, from 1,600 simulated Development visitors with rates control=0.08 and annual=0.14: annual-first converted 15.5% against 10.2%, a +53% lift with a 95% interval of +13% to +93%. These were scripted visitors, not real traffic.

Nothing further is pending. If you want annual in Production later, that is a separate decision with real traffic and its own experiment.


_Turn 4: 2 model turns, 32 s, $0.55._

