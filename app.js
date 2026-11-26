// The experiment, end to end, in ~40 lines:
//   1. identify the visitor (random id, kept in localStorage so they stay in one variant)
//   2. getExperimentFlag() -> renders the headline AND records the exposure, in one call
//   3. trackEvent('cta_click') on the button -> the conversion the metric counts
import flagsmith from 'https://cdn.jsdelivr.net/npm/@flagsmith/flagsmith@12.6.0/index.mjs';
import { CONFIG } from './config.js';

const headline = document.getElementById('headline');
const cta = document.getElementById('cta');
const debug = new URLSearchParams(location.search).has('debug');

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

async function main() {
  const identity = visitorId();
  try {
    await flagsmith.init({
      environmentID: environmentKey(),
      identity,
      enableEvents: true,
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

  if (debug) console.info('[prove-it-works]', { identity, variant: flag?.variant ?? 'control', inExperiment: flag?.experiment?.inExperiment });

  cta.addEventListener('click', () => {
    flagsmith.trackEvent(CONFIG.event);
    // The link opens in a new tab, so this page stays alive long enough to flush.
    flagsmith.flushEvents();
  });

  // Belt and braces: flush anything buffered if the visitor leaves.
  addEventListener('pagehide', () => flagsmith.flushEvents());
}

main();
