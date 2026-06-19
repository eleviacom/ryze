---
name: ryze-project
description: Ryze — Raiffeisen Youth gamified banking app built for JunctionX Tirana 2026 hackathon
metadata: 
  node_type: memory
  type: project
  originSessionId: 05ff165b-667a-4b96-a791-6ce9a534eab8
---

`Ryze` is a mobile app at `/Users/eleviacom/raiffaiesen/ryze` (Expo SDK 56, expo-router, TypeScript, zustand). It's a gamified youth banking app built to win the **Raiffeisen "Play, Invite, Belong"** challenge at **JunctionX Tirana 2026** (48h hackathon, June 19–21; €1,000 challenge prize + Golden Ticket to Helsinki for top 3).

Goal is to **win**, not just complete — judged on Innovation 25 / Business 25 / UX 20 / Architecture 20 / AI 5 / Presentation 5. No points for running microservices, so the build is a modular monolith (`src/game/`: engine, store, data, ai, types) that maps 1:1 to the brief's 6 logical services + is *drawn* as microservices + BFF on the architecture slide.

Tech is React Native/Expo because the sponsor said any tech is fine as long as it can be imported into a native app (Expo compiles to native; KMP+CMP was also suggested). Run: `cd ryze && npx expo start` (Expo Go QR) or `--web`. Note: `bun` must be on PATH for the gstack browse tool; web served at localhost:8081.

Design: **Revolut's exact visual system** (from `ryze/design-ref/REVOLUT_DESIGN.md`) with **Raiffeisen yellow `#FFE600` as the single scarce brand stamp** (replacing Revolut's cobalt). Rules: true-black `#000000` canvas, white-pill primary CTAs (accent never a button surface), yellow only for featured/active/progress, no shadows (depth via surface luminance `#16181a` + hairlines), 20px cards, pill buttons, Inter type with tight negative tracking on display. Tokens centralized in `src/constants/brand.ts` — flip `STAMP` to change the accent. User wants enterprise/$100k quality.


## Onboarding + account opening (added)
Full-screen Revolut-style flow at `src/app/onboarding.tsx`: 3-slide value carousel (swipeable, SVG illustrations) -> progressive KYC account opening -> success. Content/validation in `src/onboarding/` (content.ts flow+fields, machine.ts pure age-gate+validation with machine.check.ts test, store.ts zustand VM, legal.ts corrected disclosures, api.ts mock client). KYC collects all legally-required data the simplest way: phone+OTP, email+OTP, ID document + liveness (both simulated in the demo mock), name, DOB (hard 18+ gate), place/nationality, address, tax residency + PEP/FATCA, occupation/source of funds, 6 mandatory + 2 optional consents, notifications. On submit -> game store `setKycVerified` grants XP/coins, claims `ob-verify`, fires confetti, sets `kycStatus='verified'`, lands in (tabs).

AI buddy "Riz" in `src/buddy/` (system-prompt.ts grounded per-step, client.ts askRiz with guardInput safety + localReply offline fallback; no API key needed for demo, real proxy via EXPO_PUBLIC_RIZ_URL). FAB + chat sheet in `src/components/onboarding/parts.tsx`. 8 SVG illustrations + Giebelkreuz mark in `src/components/onboarding/illustrations.tsx` + `src/components/brand/Giebelkreuz.tsx`; official logo PNG in `src/components/brand/Logo.tsx`.

Legal (verified, Albania): data protection = Law 124/2024 (NOT repealed 9887); deposit insurance = ASD, 2,500,000 ALL; AML recipient = Financial Intelligence Agency (AIF, not GDPML); Albania-only tax id = personal NID (not NIPT); FX converted at compulsory-liquidation date; all texts are PROTOTYPE drafts needing Raiffeisen legal sign-off. Full verified spec in `ryze/design-ref/spec_*.json`.

## Native SwiftUI migration (added — user chose full rewrite)
User decided to migrate to native SwiftUI (after being warned the sponsor said React is fine and a rewrite is risky). New native app at `/Users/eleviacom/raiffaiesen/ryze-ios/` (XcodeGen `project.yml`, bundle id `al.raiffeisen.ryze`, iOS 17+ deploy, Swift 5 mode, Xcode 26.4 / Swift 6.3). Files in `ryze-ios/Ryze/`: Theme, Legal (corrected Law 124/2024 + ASD), Riz (buddy guard+local replies), OnboardingModel (flow/validation/age-gate/ID-prefill + QA env hook RYZE_PHASE/STEP/SLIDE/PREFILL/FLAGS/CONSENT), Components, OnboardingFlow (carousel + KYC container + success + Riz FAB/sheet + HomeStub).

Onboarding simplified to ~9 screens: 3-slide value carousel → phone → otp → identity (ID scan + face check combined on ONE screen) → details (prefilled from simulated ID OCR) → consents → notifications → success. Real graphics generated with nano-banana (Gemini 3 Pro Image) in `assets-gen/` and wired into `Ryze/Assets.xcassets` (welcome, openacct, domore, identity, success imagesets + RaiffeisenLogo + 1024 AppIcon on #FFE600). Hero display pattern: full-bleed `Color.clear.overlay(Image.scaledToFill)` for success; scaledToFit for identity; canvas Brand.bg = #0A0A0A to match art.

Build/run: `cd ryze-ios && xcodegen generate && xcodebuild -scheme Ryze -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath dd build` then `xcrun simctl install <udid> dd/Build/Products/Debug-iphonesimulator/Ryze.app && xcrun simctl launch <udid> al.raiffeisen.ryze`. iOS 26.4 sim runtime is installed; test device udid in /tmp/ryze-sim-udid.txt. BUILD SUCCEEDED + full onboarding verified via simulator screenshots.

NOT yet ported to SwiftUI: the 5-tab gamified app (Home/Quests/Invite/Rewards/Profile) + gamification engine — currently only a HomeStub after success. That's the next chunk. The RN app under `ryze/` still has the full version for reference/porting.

## SwiftUI: full app ported + onboarding polish (added)
The whole web app is now ported to native SwiftUI. `Game.swift` = engine (xpForLevel/levelInfo/tiers/streakMultiplier) + GameModel (ObservableObject: xp/coins/streak/missions/badges/squad/redeemed/invites + claim/dailyCheckIn/redeem/simulateReferral/completeAccount/resetDemo + seed data). `AppViews.swift` = MainTabView (5 tabs, SF Symbol icons, yellow tint, toast banner + sensoryFeedback) + Home/Quests/Invite/Rewards/Profile + components (AppCard/FeaturedCard/PillButton/IconTile/Avatar/MissionRowView/StatCard). RyzeApp → RootView gates on `game.onboarded` (OnboardingFlow → MainTabView). OnboardingFlow success calls `game.completeAccount(name:)`.

Onboarding fixes applied: images regenerated on FLAT pure-black bg (no grey) at 1:1 via nano-banana straight into the asset catalog; canvas Brand.bg = #000000; slides use centered scaledToFit (slide 3 + welcome centered/bigger); consents simplified to 2 mandatory ticks (combined agreements + biometric) + 1 optional marketing (fits, scrolls via KycContainer ScrollView); identity uses better shield art + premium SF Symbols (camera.viewfinder, faceid). Premium icons = SF Symbols throughout.

`@thesvg/mcp-server` installed (`npm i -g`, bin `thesvg-mcp`) and registered via `claude mcp add thesvg thesvg-mcp` (local config) — available next session for premium SVG icon search.

QA env hooks (debug only): RYZE_PHASE/STEP/SLIDE/PREFILL/FLAGS for onboarding screens; RYZE_HOME=1 + RYZE_TAB=n to jump into the tab app. All screens verified via simulator screenshots; BUILD SUCCEEDED.

## Pivot to real banking app (Revolut-modeled) — added
Ran a 7-agent Revolut feature study (web-grounded) → blueprint in `ryze-ios/design-ref/revolut_ia.json` + `revolut_studies.json`. Restructured the SwiftUI app from quests-first to a real bank with 5 tabs: **Home / Pay / Cards / Grow / Profile** (gamification folded into Profile).
- `Bank.swift` = BankModel (ObservableObject) + Account/Txn/Contact/PayMsg/PaymentCard/Goal/SpendCat + mock data + actions (send/request/payRequest/sendText/addMoney/fundGoal/toggleFreeze); emits events to GameModel via `realAction(...)` for XP. `money()` helper.
- `AppViews.swift` rewritten: HomeView balance-first (total balance + account chips + quick actions + slim gamification strip + grow snapshot + Riz nudge + transactions), PayView hub (NavigationStack, action row, requests, frequent + all contacts), ChatThreadView (iMessage-for-money: text + send/request payment bubbles with status + Pay button), CardsView (card visual, freeze, reveal, security toggles, order/skins), GrowView (savings goals w/ rings + round-ups + spending analytics bars + exchange), ProfileView (level/tier, stats, quests reframed to REAL actions, badges, rewards store, referral ShareLink, security, Riz).
- Game.swift missions reframed to real actions (m-topup/m-transfer/m-split/m-goal/m-checkin/m-roundup/s-invite + ob-verify); added `realAction()`.
- RyzeApp provides GameModel + BankModel; `bank.game = game` in RootView.onAppear.
- Fixes: welcome hero = real Raiffeisen logo (LogoHero, glow+sparkles); ScrollView bottom padding 110 (scroll clears tab bar); onboarding images regenerated on flat black; consents simplified to 2 ticks.
- QA env: RYZE_HOME=1, RYZE_TAB=0..4, RYZE_THREAD=<contactId> to deep-link for screenshots.

NEXT (section-by-section optimization per user): real send/request polish + biometric step-up, Scan/Bank-transfer/Exchange flows (currently stubs), transaction detail + split-from-feed, notifications, persistence. @thesvg/mcp-server installed+registered (use next session for premium SVG icons).

## Polish pass (added)
- Scroll FIX (was broken with iOS 26 floating tab bar): `ScreenScroll` now uses `.contentMargins(.bottom, 96, for: .scrollContent)` + ScrollViewReader, NOT inner bottom padding. Verified by auto-scrolling Profile to the last element. Don't revert to padding-only.
- Premium palette: `Brand.gold` LinearGradient (#FFE600→#F5B700) on FeaturedCard + QuickAction circles (with soft yellow glow shadow); IconTile uses `.symbolRenderingMode(.hierarchical)`. Brand.yellow stays the stamp.
- Welcome hero = real Raiffeisen logo (LogoHero: 156pt logo + gold radial glow + ring + sparkles + shadow).
- QA env RYZE_SCROLLBOTTOM auto-scrolls a screen to bottom for screenshot verification.

## IA pivot to Revolut-style + LUMA-inspired polish (added)
New tabs: **Home · Cards · Pay · Assistant · Rewards** (Grow folded into Home sheet; Profile opens from the top-bar avatar as a sheet). New files: `Plans.swift` (youth plan tiers Free/Plus/Pro/Metal + Upgrade screen), `Sections.swift` (TopBar, ProfileSheet, AssistantView = Riz as its own tab, RewardsHub = RevPoints-style points hero + Earn/Redeem/Plan perks + Products grid + brand offers + top brands + challenges + insights). Plans + Rewards designed from a 2nd Revolut study workflow (`design-ref/` has revolut_ia.json + plans-rewards output). Points shown as RyzePoints (= game.coins).
- SwiftUI gotcha fixed: multiple `.sheet(isPresented:)` on one view → only last fires. Use ONE `.sheet(item:)` with an enum (HomeView homeSheet, RewardsHub rewardsSheet).
- Scroll FIX (final): `ScreenScroll` is now a plain vanilla `ScrollView` + big bottom padding (140). Dropped ScrollViewReader/contentMargins (were misbehaving on cmd+R sim). 
- Riz removed from onboarding entirely (Assistant tab only); onboarding "Why do we need it?" now opens a plain WhyInfo sheet. Added a dev "Skip ›" button (top-right of value carousel) that calls game.completeAccount.
- Design direction: LUMA (Behance) used as INSPIRATION only (not cloned, IP) → applied originally: `.fontDesign(.rounded)` app-wide, glassy gradient AppCard + soft shadows + 24pt radius, gold-gradient FeaturedCard with glow. Keeps Raiffeisen yellow/black; softer/friendlier than the flat Revolut look.
