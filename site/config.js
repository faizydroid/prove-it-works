// Client-side environment keys are public by design (they ship in every browser bundle),
// so they live here. Server-side and admin keys never belong in this repo.
export const CONFIG = {
  // Hostname -> Flagsmith client-side environment key.
  // Real visitors (GitHub Pages) land in `production`; everything else (localhost, previews)
  // uses `development`, which is where scripted traffic goes.
  environments: {
    'faizydroid.github.io': 'hBLGZrbouE5zkSp7dYgWjG', // toggle-wars / Production
    default: 'dMF4K5LSSqPndCs8DprMKJ', // toggle-wars / Development
  },
  flag: 'landing_headline',
  event: 'cta_click',
  guardrailEvent: 'example_viewed',
  // Shown only if Flagsmith cannot be reached. Same text as control; never recorded as an exposure.
  fallbackHeadline: 'Run A/B tests from your coding agent.',
};
