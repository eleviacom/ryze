# Ryze — Brand & Design System

The single source of truth for how Ryze looks and feels. Apply this to every new section so the
whole app stays one premium, distinctive product. Tokens live in `Ryze/Theme.swift`; shared
components in `Ryze/Components.swift` + `Ryze/AppViews.swift`.

## 1. Essence
Premium, calm, youthful banking for Raiffeisen (18–25, Albania). Dark, confident, friendly — not
austere. Three pillars: **scarce gold**, **glass depth**, **the hexagon signature**. Never looks like
a Revolut clone: depth + warmth + the hexagon are ours.

## 2. Color tokens (`Brand`)
| Token | Hex | Use |
|---|---|---|
| `void` | #000000 | ONLY the balance hero + onboarding canvas (lets flat-black art blend) |
| `bg` | #0B0B0D | App canvas (warm graphite, not pure black) |
| `elev1` | #141417 | Card bottom of gradient |
| `elev2` / `surface` | #1B1B1F | Card top of gradient, chips, fields, neutral circles |
| `elev3` / `surfacePressed` | #232328 | Pressed / highest surface |
| `yellow` | #FFE600 | SCARCE: rings, ticks, glyphs, progress, the eyebrow tick — never a big fill |
| `gold` (gradient) | #FFE45C→#F2C200→#CF9A00 | The ONE premium fill: primary action, featured card, hero accents |
| `goldEdge` | #FFF0A8 | Specular edge on gold surfaces |
| `text` | white | Primary text |
| `mute` | white 62% | Secondary text |
| `faint` | white 40% | Tertiary / captions / disabled |
| `hairline` | white 8% | The ONLY border token |
| `good` | #3CE0A0 | Positive amounts, success ticks |
| `danger` | #E23B4A | Destructive / errors |
| `violet/mint/pink` | — | Illustration / category accents ONLY, never UI chrome |

**Gold rule (most important):** gold is scarce ink. Per screen, at most ONE gold fill (the primary
action or the featured surface). Everything else is neutral glass with yellow only as a thin accent.

## 3. Elevation & materials
Depth comes from luminance + a specular edge + a 2-layer shadow — NOT from flat black-on-black.
- **AppCard (glass):** background = `LinearGradient([elev2, elev1], .top→.bottom)` + a top sheen
  `LinearGradient([white 6%, clear], .top→.center)`; `.specularBorder(24)`; clip `RoundedRectangle(24)`;
  shadows = contact `black 60% r2 y1` + ambient `black 40% r22 y14`.
- **FeaturedCard (gold):** `Brand.gold` fill + softLight sheen `[white 30%, clear] .topLeading→.center`
  + `goldEdge 50%` stroke + clip(24) + glow `yellow 26% r22 y12`.
- **Balance/points hero (void):** `Brand.void` fill + top-leading gold `RadialGradient([#F2C200 13%, clear])`
  + `.specularBorder(24)` + soft shadow. Reserved for the one hero number per screen.
- **Radii:** tiles/chips 12–14, cards/heroes 24, pills = Capsule. **Border:** always `hairline` (white 8%).
- Helpers: `.specularBorder(_ radius)` (top-lit stroke). Sheets: `.presentationCornerRadius(28)`.

## 4. Typography
- Global: `.fontDesign(.rounded).monospacedDigit()` on `RootView` — rounded + tabular figures everywhere
  (numbers never reflow).
- Scale (size / weight): hero 46 bold · display 34 bold · title 22 semibold · headline 17 semibold ·
  body 15 medium · label 13 · caption 11. Display uses tight tracking (~-0.025·size).
- Hero numbers: 46 bold rounded, gradient ink `LinearGradient([white, white 78%], .top→.bottom)`,
  `.contentTransition(.numericText())` so they roll like an odometer.
- 3-weight discipline: **medium** body, **semibold** interactive/labels, **bold** display. Avoid in-betweens.
- **Eyebrow:** 11 semibold, tracking 1.4, UPPERCASE, `faint`, with a 14×2 `yellow` leading tick
  (`Eyebrow(text:)` / private `eyebrow(_:)`) — a repeated micro-signature.

## 5. Spacing & rhythm
4-based: 4 / 8 / 12 / 16 / 20 / 28. Card padding 18–20. Section gaps: 28 major, 12 grouped.
Screen content: horizontal 20, scrolls via vanilla `ScrollView` + generous bottom padding (≈140) so the
last item clears the floating tab bar (do NOT rely on `.contentMargins` — it misbehaved).

## 6. Components (reuse these — don't hand-roll)
- `AppCard { }` — the glass container for everything.
- `FeaturedCard { }` — the single gold surface (balance/points/plan hero blocks on light).
- `PrimaryButton(title:enabled:action:)` — white pill, black text, spring press.
- `PillButton(title:system:style:.primary/.dark/.soft:)` — small pills (white / black / glass).
- `QuickAction(icon:label:prominent:action:)` — 52pt circle row; `prominent:true` = gold+glow (use on
  ONE per row), else neutral glass + hairline.
- `IconTile(system:color:size:)` — hierarchical SF Symbol on a 13pt-rounded tinted tile.
- `Avatar(name:size:you:)` — initial in a circle (`you` = yellow).
- `Ring(v:size:)` — yellow circular progress. `ProgressBar(value:)` / `Bar(v:)` — yellow track fill.
- `Eyebrow(text:)` — section label with the yellow tick. `StatCard(value:label:)` — stat tile.
- `MissionRowView(m:)` — quest/challenge row. `ToastBanner(toast:)` — top reward toast.
- `AmountSheet(mode:.send/.request/.add/.fund)` — money entry sheet.

## 7. The signature — the Ryze hexagon
- `Hexagon: Shape` — flat-top hexagon. Used as the points glyph (`hexagon.fill`), outline accents,
  and celebration particles.
- `CelebrationOverlay(trigger:)` — yellow+white hexagon particles bursting outward; mounted in
  `MainTabView` and fired by `game.celebrate` (every claim / redeem / check-in / account-opened).
  Reuse it on any "win" moment.
- Gold surfaces get a single diagonal sheen (softLight white gradient). Reuse the same sheen recipe.
- Hero numbers roll (numericText). Icons that react use `.symbolEffect(.bounce, value: trigger)`.

## 8. Motion
- Buttons: `PressStyle` (spring scale 0.95) on every tappable control; success haptic on celebrate.
- Numbers: `.contentTransition(.numericText())` + `withAnimation(.snappy)`.
- Reveal/hide: blur + crossfade (e.g. balance hide-eye) with `.smooth(0.35)`; `.symbolEffect(.bounce)`.
- KYC/step changes: slide+fade transitions. Keep motion tasteful — one orchestrated moment beats many.

## 9. Icons
SF Symbols only, `.symbolRenderingMode(.hierarchical)`, filled variants for tabs/active, outline for
idle. Tabs: Home `house.fill` · Cards `creditcard.fill` · Pay `paperplane.fill` · Assistant `sparkles`
· Rewards `gift.fill`. Tab tint = `Brand.yellow`.

## 10. Do / Don't
- DO: scarce gold, glass depth, tabular numerals, the hexagon for wins, the eyebrow tick, `hairline`
  for every border, `AppCard`/`FeaturedCard` for surfaces.
- DON'T: more than one gold fill per screen, pure-black app surfaces (only `void` for the hero),
  drop shadows without lifted bg, mixed border opacities, ad-hoc font sizes, generic confetti (use hexagons).

## 11. Apply to a NEW section — checklist
1. Wrap surfaces in `AppCard`; one hero in `FeaturedCard` or the void-hero recipe.
2. Section labels = `Eyebrow(text:)`. Titles = display/title weights.
3. Numbers: rounded bold + `.contentTransition(.numericText())` for any hero figure.
4. Actions: `PrimaryButton` or `QuickAction(prominent:)` — exactly one gold accent.
5. Borders = `hairline`; radii 24 (cards) / Capsule (pills) / 12–14 (tiles).
6. Any "win" → bump `game.celebrate` for the hexagon burst + haptic.
7. Reuse `IconTile`, `Avatar`, `Ring`, `MissionRowView`. Add `.buttonStyle(PressStyle())` to custom buttons.
