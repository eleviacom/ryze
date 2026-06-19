// Ryze design tokens — Revolut's exact visual system, Raiffeisen yellow as the
// single scarce brand stamp. Source: design-ref/REVOLUT_DESIGN.md.
// Rules enforced here: true-black canvas, no shadows (depth via surface luminance
// + hairlines), pills for buttons, 20px cards, accent reserved for stamps only.

// One place to flip the stamp (e.g. back to Revolut cobalt #494fdf).
const STAMP = '#FFE600';
const STAMP_PRESSED = '#E6CF00';

export const C = {
  black: '#000000', // canvas-dark — true black, never near-black
  white: '#ffffff', // canvas-light

  surfaceSoft: '#f4f4f4', // off-white inset on light bands
  surfaceDeep: '#0a0a0a', // inset card on dark
  surfaceElevated: '#16181a', // card on dark — lifts off black via luminance
  surfacePressed: '#202327',

  hairline: 'rgba(255,255,255,0.12)', // 1px divider on dark
  hairlineLight: '#e2e2e7',
  divider: 'rgba(255,255,255,0.06)',

  onDark: '#ffffff',
  onDarkMute: 'rgba(255,255,255,0.72)',
  onDarkFaint: 'rgba(255,255,255,0.45)',

  ink: '#191c1f',
  mute: '#505a63',
  stone: '#8d969e',
  faint: '#c9c9cd',

  accent: STAMP,
  accentPressed: STAMP_PRESSED,
  onAccent: '#000000',

  // positive/negative — used scarcely as text, never as button surfaces
  pos: '#3CE0A0',
  danger: '#e23b4a',

  // illustration / icon-tile accents only (Revolut: never as buttons)
  cobalt: '#494fdf',
  teal: '#00a87e',
  pink: '#e61e49',
  blue: '#2f7bd6',
  orange: '#ec7e00',
  green: '#4caf50',
} as const;

export const R = { none: 0, sm: 8, md: 12, lg: 20, xl: 28, full: 9999 } as const;

export const S = {
  xxs: 4, xs: 6, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48, block: 64,
} as const;

export const FONTS = {
  regular: 'Inter_400Regular',
  medium: 'Inter_500Medium',
  semibold: 'Inter_600SemiBold',
  bold: 'Inter_700Bold',
} as const;

// Mobile-tuned type scale. Display uses tight negative tracking + lineHeight ~1.0
// to mimic Aeonik Pro; body is Inter with the spec's positive tracking.
type TStyle = { fontFamily: string; fontSize: number; lineHeight: number; letterSpacing: number };
const t = (fontFamily: string, fontSize: number, lh: number, letterSpacing: number): TStyle => ({
  fontFamily, fontSize, lineHeight: Math.round(fontSize * lh), letterSpacing,
});

export const T = {
  displayXl: t(FONTS.bold, 46, 1.0, -1.4), // one hero per screen
  displayLg: t(FONTS.bold, 34, 1.04, -0.9),
  h1: t(FONTS.semibold, 28, 1.1, -0.5),
  h2: t(FONTS.semibold, 22, 1.2, -0.3),
  h3: t(FONTS.semibold, 18, 1.3, -0.1),
  bodyLg: t(FONTS.regular, 17, 1.5, -0.1),
  body: t(FONTS.regular, 15, 1.47, 0.2),
  bodyBold: t(FONTS.semibold, 15, 1.47, 0.1),
  bodySm: t(FONTS.regular, 13, 1.4, 0.1),
  button: t(FONTS.semibold, 16, 1.25, 0.2),
  buttonSm: t(FONTS.semibold, 14, 1.2, 0.2),
  caption: t(FONTS.medium, 12, 1.35, 0.2),
  // eyebrow / section label — small, tracked-out, uppercase set at call site
  eyebrow: t(FONTS.semibold, 12, 1.3, 1.4),
} as const;
