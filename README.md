# Ryze — gamified youth banking for Raiffeisen
> **JunctionX Tirana 2026** · Team **PentaByte** · Track: Raiffeisen **"Play, Invite, Belong"**

Ryze turns a young person's first bank account into something they actually *want* to use:
real Raiffeisen banking wrapped in an AI money coach, social payments, savings goals, and a
rewards game. **Punchline: banking that levels up with you.**

## Highlights
- **2-minute onboarding** — online KYC (phone, OTP, ID scan, face check), Albania-correct, EN/SQ.
- **Riz** — an AI money coach that answers from your real data, with safety guardrails + offline fallback.
- **Social money** — pay/request in chat (money bubbles), split bills with your crew.
- **Cards** — virtual + physical, freeze & limits, a Card Studio to personalise.
- **Grow** — savings goals with round-ups + spending analytics.
- **Gamification (Play · Invite · Belong)** — streaks, levels (Rookie→Elite), AI missions tied to real
  money actions, a squad goal, and a points store with real coupons (Spotify, KFC) redeemed by QR.

## Repo layout
| Path | What |
|---|---|
| `ryze-ios/` | **The product** — native SwiftUI app (iOS 17+). |
| `ryze/` | Earlier React Native / Expo reference implementation. |
| `ryze-ios/BRANDING.md` | Design system (warm-dark canvas, scarce Raiffeisen yellow stamp). |
| `screenshots/` | 48 screenshots of every app screen (EN, dark) + `capture.sh` to regenerate. |
| `ryze-video/` | Demo-video + pitch-deck pipeline (Remotion). |
| `ryze-deck.pdf` | Pitch deck.  ·  `SUBMISSION.md` | Submission copy. |

## Build & run (iOS)
Requires Xcode 16+ and an iOS 17+ simulator.
```bash
cd ryze-ios
xcodegen generate          # generates Ryze.xcodeproj from project.yml
open Ryze.xcodeproj         # run on an iPhone simulator (Cmd+R)
```
CLI alternative:
```bash
cd ryze-ios && xcodegen generate
xcodebuild -scheme Ryze -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath dd build
xcrun simctl install booted dd/Build/Products/Debug-iphonesimulator/Ryze.app
SIMCTL_CHILD_RYZE_HOME=1 xcrun simctl launch booted al.raiffeisen.ryze
```

### Demo deep-links (for judges)
The app seeds a demo user ("Klevi") and reads `RYZE_*` env vars so you can jump to any screen:
```bash
# straight into the gamified app
SIMCTL_CHILD_RYZE_HOME=1 xcrun simctl launch booted al.raiffeisen.ryze
# pick a tab: 0 Home · 1 Cards · 2 Pay · 3 Riz · 4 Rewards
SIMCTL_CHILD_RYZE_HOME=1 SIMCTL_CHILD_RYZE_TAB=4 xcrun simctl launch booted al.raiffeisen.ryze
# ask Riz live
SIMCTL_CHILD_RYZE_HOME=1 SIMCTL_CHILD_RYZE_TAB=3 \
  SIMCTL_CHILD_RYZE_ASK="How am I spending this month?" \
  xcrun simctl launch booted al.raiffeisen.ryze
```
Force locale/theme with `RYZE_LANG=en|sq` and `RYZE_APPEARANCE=dark|light`.

## Links
- **Demo video:** _(coming)_
- **Pitch deck:** [`ryze-deck.pdf`](./ryze-deck.pdf)
- **Team:** PentaByte — JunctionX Tirana 2026
