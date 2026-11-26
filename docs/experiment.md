# Experiment: problem-led vs product-led headline

**Status:** pre-registered and running. This file was committed before the first real visitor;
the git history is the timestamp. Results are added on Sunday, Nov 29, 2026, below the line at the
end. Nothing above that line changes after the experiment starts.

| | |
|---|---|
| Page | https://faizydroid.github.io/prove-it-works/ |
| Flagsmith project / environment | `toggle-wars` / Production |
| Experiment | 715, "Landing headline: problem-led vs product-led" |
| Flag | `landing_headline` (multivariate, string) |
| Metric | `cta_click`, occurrence: did the visitor click "Get the skill on GitHub" at least once |
| Set up with | this repo's own skill, `skills/prove-it-works` (commands at the end) |

## Hypothesis

> Opening with the reader's problem ("Stop guessing which version wins") instead of describing the
> product ("Run A/B tests from your coding agent") raises the share of visitors who click
> **Get the skill** by at least 20% relative, on real visitors from Nov 27 to Nov 29, 2026.

Why this question: every landing page has to choose between saying what the thing *is* and saying
what problem it *ends*. Copywriting advice usually says "lead with the problem". Developers skim and
distrust marketing, so for this audience that advice may well be wrong. The test settles it for one
real page.

| Variant | Key | Headline (the flag value) |
|---|---|---|
| Control, product-led | `control` | Run A/B tests from your coding agent. |
| Treatment, problem-led | `problem` | Stop guessing which version wins. Let your agent prove it. |

Everything else on the page is identical. Only the `<h1>` text comes from the flag.

## Design

- **Who is in it:** every visitor to the GitHub Pages site. Rollout 100%, split 50/50.
- **Identity:** a random UUID stored in the browser's `localStorage`, so a returning visitor stays
  in the same variant. One browser = one identity; the same person on two devices counts twice.
- **Exposure:** `getExperimentFlag('landing_headline')` at the moment the headline is rendered,
  which records the exposure in the same call. A visitor who never sees the headline is not in the
  results.
- **Conversion:** `trackEvent('cta_click')` on the GitHub button, flushed straight away. It fires
  early in a visit, which suits a three-day test. Flagsmith counts conversions only after a
  visitor's first exposure.
- **Statistics:** Flagsmith's Bayesian engine. It reports lift, a 95% credible interval and the
  chance that `problem` beats `control`. Inference starts at 50 identities and 5 conversions per
  variant.

## Keeping the data clean

- **Our own visits are excluded:** opening the page once with `?internal` marks that browser. It
  still renders the experiment but sends no events. Every device we test on gets marked.
- **Sample ratio check:** if the split drifts from 50/50 more than chance allows (p < 0.001), the
  numbers are void and we say so instead of reading them.
- **Mixed exposures:** Flagsmith quarantines identities that saw both variants.
- **Simulated traffic never touches this experiment.** Scripted users go only to the Development
  environment, which has its own experiment (714).

## Decision rule, fixed in advance

Read once, on Sunday, Nov 29, 2026, before the 8 PM IST deadline, using `results.sh`:

| If | Then |
|---|---|
| `problem` has a ≥ 95% chance to beat control **and** its 95% interval is above zero | ship `problem` to everyone with `rollout-winner.sh`, then remove the flag from the code |
| `problem` has a ≤ 5% chance **and** its interval is below zero | keep `control`, end the experiment |
| anything else | **inconclusive**: keep `control` (no change needed), publish the numbers and what it would take to decide |
| sample ratio mismatch | no decision; report the broken split and its cause |

During the run we watch the dashboard only to confirm data is arriving. The decision is not taken
early because one day looks good.

## How much traffic would settle it (honest numbers)

With a baseline click-through around 10%:

- detecting a **20% relative lift** (10% → 12%) reliably needs about **3,800 visitors per variant**;
- detecting a **doubling** (10% → 20%) needs about **200 per variant**.

(Standard two-proportion estimate, 95% confidence, 80% power. Flagsmith's Bayesian engine works
differently, but the order of magnitude holds.)

We expect a few hundred visitors from the hackathon Discord and social posts. So only a large
effect is likely to reach the 95% bar by Sunday. If the real effect is smaller, the honest result
is "inconclusive", and that is reported as the result, not dressed up.

## How it was set up

All with the skill in this repo, against Flagsmith Cloud:

```
FLAGSMITH_ENVIRONMENT=<production client key> bash skills/prove-it-works/scripts/create-experiment.sh \
  --flag landing_headline \
  --control "Run A/B tests from your coding agent." \
  --variant problem="Stop guessing which version wins. Let your agent prove it." \
  --event cta_click --name "Landing headline: problem-led vs product-led" \
  --hypothesis "Opening with the reader's problem ... by at least 20% relative ..."
FLAGSMITH_ENVIRONMENT=<production client key> bash skills/prove-it-works/scripts/start-experiment.sh --id 715
```

The instrumentation is the ~70 lines in [`site/app.js`](../site/app.js).

---

## Results

_Added on Sunday, Nov 29, 2026._
