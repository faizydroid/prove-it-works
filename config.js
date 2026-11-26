// Client-side environment keys are public by design (they ship in every browser bundle),
// so they live here. Server-side and admin keys never belong in this repo.
export const CONFIG = {
  // Hostname -> Flagsmith client-side environment key.
  // Real visitors (GitHub Pages) land in `production`; everything else (localhost, previews)
  // uses `development`, which is where scripted traffic goes.
  environments: {
    'faizydroid.github.io': 'REPLACE_WITH_PRODUCTION_CLIENT_KEY',
    default: 'REPLACE_WITH_DEVELOPMENT_CLIENT_KEY',
  },
  flag: 'landing_headline',
  event: 'cta_click',
  // Shown only if Flagsmith cannot be reached. Never recorded as an exposure.
  fallbackHeadline: 'Run A/B tests from your coding agent.',
};
