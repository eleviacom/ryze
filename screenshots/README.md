# Ryze — app screenshot library

48 screenshots covering every screen of the Ryze app (iPhone 17 Pro, iOS 26,
English, dark theme, clean 9:41 status bar). Generated from the live app, not mocked.

## Regenerate

```bash
# 1. build + install the app on a booted simulator
cd ryze-ios
xcodebuild -project Ryze.xcodeproj -scheme Ryze -configuration Debug \
  -destination 'platform=iOS Simulator,id=<BOOTED_UDID>' -derivedDataPath dd \
  CODE_SIGNING_ALLOWED=NO build
xcrun simctl install booted dd/Build/Products/Debug-iphonesimulator/Ryze.app
# 2. drive every screen via the app's RYZE_* launch-env hooks
bash ../screenshots/capture.sh
```

`capture.sh` launches the app once per screen with `SIMCTL_CHILD_RYZE_*` env vars
(`RYZE_VIEW`, `RYZE_TAB`, `RYZE_PHASE`/`RYZE_STEP`/`RYZE_SLIDE`, `RYZE_HOME`,
`RYZE_PREFILL`/`RYZE_FLAGS`/`RYZE_CONSENT`, `RYZE_THREAD`, `RYZE_RIZ`, …) — the same
QA hooks wired into `RyzeApp.swift` / `OnboardingModel.swift` / `Bank.swift` / `Game.swift`.

## Contents

| # | Screen |
|---|--------|
| 01–03 | Onboarding — welcome carousel |
| 04–14 | Onboarding — KYC: phone, OTP, passcode, Face ID, details, address, usage, identity, consents, notifications, plan |
| 15 | Onboarding — account-opened success |
| 16 | First-run welcome challenges — slides up the first time you enter the app |
| 17–22 | Tabs — Home, Cards, Pay, Assistant (Riz), Riz answer, Rewards |
| 23–27 | Pay — chat thread, split bill, scan, bank transfer, QR |
| 28–29 | Add money — methods (Apple Pay / card / bank / ATM), ATM map |
| 30–31 | Money — exchange, analytics |
| 32–34 | Grow — savings goals, new goal, goal detail |
| 35–39 | Cards — studio, order, limit, Apple Pay, virtual |
| 40–43 | Rewards — redeem store, earn, coupon, plans |
| 44–46 | Account — profile, settings, search |
| 47–48 | Gamification — unlockable discovery map over real Tirana streets (locked, partially unlocked) |

Not drivable via env hooks (need tapping, omitted): transaction-history sheet.
Available on request: light mode and Albanian (`RYZE_APPEARANCE=light`, `RYZE_LANG=sq`).
