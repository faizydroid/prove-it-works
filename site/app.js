// The experiment, end to end:
//   1. identify the visitor (random id, kept in localStorage so they stay in one variant)
//   2. getExperimentFlag() -> renders the headline AND records the exposure, in one call
//   3. trackEvent('cta_click') on the button -> the conversion the metric counts
// Visiting once with ?internal marks this browser as the team's own: it still renders the
// experiment, but sends no events, so our own visits never land in the results.
import flagsmith from 'https://cdn.jsdelivr.net/npm/@flagsmith/flagsmith@12.6.0/index.mjs';
import { CONFIG } from './config.js';

const headline = document.getElementById('headline');
const cta = document.getElementById('cta');
const params = new URLSearchParams(location.search);
const debug = params.has('debug');

if (params.has('internal')) localStorage.setItem('piw_internal', '1');
const internal = localStorage.getItem('piw_internal') === '1';

function visitorId() {
  let id = localStorage.getItem('piw_visitor');
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem('piw_visitor', id);
  }
  return id;
}

function environmentKey() {
  return CONFIG.environments[location.hostname] ?? CONFIG.environments.default;
}

function showInternalBadge() {
  const note = document.createElement('p');
  note.className = 'internal';
  note.textContent = 'Internal visit: not counted in the experiment.';
  document.querySelector('footer').append(note);
}

async function main() {
  const identity = visitorId();
  try {
    await flagsmith.init({
      environmentID: environmentKey(),
      identity,
      enableEvents: !internal,
      enableLogs: debug,
    });
  } catch (err) {
    console.warn('Flagsmith unavailable, showing fallback headline', err);
    headline.textContent = CONFIG.fallbackHeadline;
    return;
  }

  // Exposure is recorded here, at the moment the visitor actually sees the variation.
  const flag = flagsmith.getExperimentFlag(CONFIG.flag);
  headline.textContent = (flag?.enabled && typeof flag.value === 'string' && flag.value) || CONFIG.fallbackHeadline;
  document.body.dataset.variant = flag?.variant || 'control';
  if (internal) showInternalBadge();

  if (debug) {
    console.info('[prove-it-works]', JSON.stringify({ identity, internal, variant: flag?.variant ?? 'control', inExperiment: flag?.experiment?.inExperiment ?? false }));
  }

  cta.addEventListener('click', () => {
    flagsmith.trackEvent(CONFIG.event);
    // The link opens in a new tab, so this page stays alive long enough to flush.
    flagsmith.flushEvents();
  });

  // Guardrail metric, not expected to move: did the visitor scroll far enough to see the example
  // output? If the winning headline earned clicks but fewer people read the page, we want to know.
  const example = document.querySelector('.term');
  if (example && 'IntersectionObserver' in window) {
    const watcher = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) {
        flagsmith.trackEvent(CONFIG.guardrailEvent);
        watcher.disconnect();
      }
    }, { threshold: 0.5 });
    watcher.observe(example);
  }

  // Flush anything still buffered if the visitor leaves.
  addEventListener('pagehide', () => flagsmith.flushEvents());
}

main();
