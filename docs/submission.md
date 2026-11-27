# Submission text (copy into the form)

**Project name:** prove-it-works

**Tagline (one line):** An Agent Skill that runs a whole Flagsmith A/B test, from flag to verdict
to cleanup PR, and refuses unsafe moves.

**Track:** 04, Flagsmith Agent Skills. (If two entries are allowed, also 01, Test Something Real,
with the landing-page experiment below.)

**Team:** solo, faizydroid

**Links**
- Repo: https://github.com/faizydroid/prove-it-works
- Skill: https://github.com/faizydroid/prove-it-works/tree/main/skills/prove-it-works
- Demo run, agent's PRs: https://github.com/faizydroid/prove-it-works-demo/pulls?q=is%3Apr
- Demo run write-up and token count: https://github.com/faizydroid/prove-it-works/blob/main/docs/demo-run.md
- Live experiment on real users: https://faizydroid.github.io/prove-it-works/
- Video: _add the link_

## Short description (about 60 words)

prove-it-works is an Agent Skill that takes a coding agent through a complete Flagsmith experiment
with the Flagsmith CLI. It creates the flag, metric and experiment, instruments the code, reads the
Bayesian verdict, rolls out the winner, deletes the flag from the code and archives it. Six
scripts each return one JSON line, and they refuse unsafe moves even if the agent asks.

## Long description

**Problem.** Agents can add a flag, but the work after that is where teams get hurt: proving the
change helped, shipping the winner, and removing the flag before it becomes debt. It's a chain of
CLI calls, API payloads and statistical judgement calls, and each one can touch production by
accident.

**What it does.** One `SKILL.md` (about 2,300 tokens) and six bash scripts on the Flagsmith CLI v2
(`--json`/`--jq`, `flagsmith api`). The agent follows ten steps: preflight, design, create, instrument,
start, traffic, verdict, rollout, cleanup PR, archive. The human approves every change users can
see. Every script returns one JSON line, so raw API payloads never reach the model.

**Proof.** Claude Code ran the whole job on a demo app that had never used Flagsmith. It took 4
human messages and opened 2 real PRs, one of them fixed after code review. It read *inconclusive*
at 600 simulated visitors and stopped to ask instead of shipping. At 1,600 it read *winner*,
rolled out, removed every flag line in a second PR and archived the flag. Total: 1.19M tokens
processed (mostly cache reads of the agent's own context). The skill's instructions, one reference
file and all nine script outputs added about 4,600 of them.

**Safety, enforced in the scripts:**
- Rollout is refused unless the results name that variant the winner (95% chance and an interval
  above zero). It's also refused on a sample-ratio mismatch and when a guardrail metric drops.
- The flag's state is saved and a rollback command printed before anything changes.
- Production environments need their exact name confirmed, and a mismatched name is refused.
- Experiments are created at 0% so nothing is served before the start.
- Archiving needs the cleanup PR merged, no code references left, and no unfinished experiment in
  any environment.

**Found while building, and handled in the skill:**
- Flagsmith applies an experiment's rollout at creation, not at start.
- The beta's sample-ratio check returns nothing for variants added at weight 0, so `results.sh`
  runs its own chi-squared test.
- After a rollout, unidentified requests still get control, so the cleanup step hardcodes the
  winner.

**Also a real experiment.** The skill's landing page A/B tests a problem-led against a
product-led headline on real visitors. It has a guardrail metric, internal traffic excluded, and a
hypothesis, decision rule and power estimate registered before the first visitor.

**Built with:** Flagsmith Cloud (Experimentation beta, managed warehouse), Flagsmith CLI v2,
`@flagsmith/flagsmith` 12.6 (events), bash, gh, Claude Code, GitHub Pages.
