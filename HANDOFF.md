# Ryze — session handoff (move to another Mac)

Raiffeisen Youth banking app for JunctionX Tirana 2026. Two apps in this repo:
- **ryze-ios/** — the ACTIVE native SwiftUI app (build & run this).
- **ryze/** — earlier Expo/React Native version (reference / port source).

## Build & run the SwiftUI app (primary)
```bash
brew install xcodegen           # one-time
cd ryze-ios && xcodegen generate
open Ryze.xcodeproj             # press ⌘R on an iPhone simulator
```
- Needs Xcode 26.x + an iOS 26 Simulator runtime (Xcode ▸ Settings ▸ Components, or `xcodebuild -downloadPlatform iOS`).
- Bundle id `al.raiffeisen.ryze`. Sources in `ryze-ios/Ryze/`.

## App structure (SwiftUI, ryze-ios/Ryze/)
- Tabs: Home · Cards · Pay · Assistant · Rewards. Profile opens from the top-bar avatar.
- `RyzeApp.swift` RootView (gates onboarding vs MainTabView) · `Theme.swift` (Brand colors + gold gradient, `.fontDesign(.rounded)`) ·
  `Game.swift` (GameModel engine: XP/level/tier/missions/badges + RyzePoints) · `Bank.swift` (BankModel: accounts/txns/contacts/cards/goals + send/request/split) ·
  `AppViews.swift` (MainTabView, Home, Pay + chat threads, Cards, Grow, components, ScreenScroll) ·
  `Sections.swift` (TopBar, ProfileSheet, AssistantView=Riz tab, RewardsHub) · `Plans.swift` (youth plan tiers + Upgrade screen) ·
  `OnboardingFlow.swift` (value carousel + KYC + success; Skip dev button) · `OnboardingModel.swift`, `Legal.swift`, `Riz.swift`, `Components.swift`.
- Assets in `ryze-ios/Ryze/Assets.xcassets` (nano-banana heroes + official Raiffeisen logo + AppIcon).

## QA env hooks (Scheme ▸ Run ▸ Environment, or simctl SIMCTL_CHILD_*)
RYZE_HOME=1 (skip to app) · RYZE_TAB=0..4 · RYZE_SHEET=profile|plans|grow · RYZE_THREAD=<contactId> · RYZE_VIEW=profile|plans · RYZE_SCROLLBOTTOM=1.

## Design references
- `ryze-ios/design-ref/` and `ryze/design-ref/` — Revolut design spec + IA + plans/rewards study (JSON).
- Direction: true-black + Raiffeisen yellow #FFE600 (gold gradient), LUMA-inspired soft/glassy/rounded polish (original, not a clone).

## Tools used this session (install on the Air to keep working)
- Xcode 26 + iOS sim runtime; Homebrew; `xcodegen`; node 22 + bun (for the RN app / gstack browse).
- MCP/skills (optional): nanobanana (image gen), gstack `/browse`, `@thesvg/mcp-server` (`npm i -g @thesvg/mcp-server` then `claude mcp add thesvg thesvg-mcp`).

## Claude continuity
- `.handoff/memory/` holds this project's Claude memory. On the Air, start a fresh Claude Code session in this folder and tell it to read `HANDOFF.md` + `.handoff/memory/ryze-project.md` to resume with full context.

## Open follow-ups
- Confirm scroll works on ⌘R (ScreenScroll is now a vanilla ScrollView).
- Refine LUMA-inspired direction across all tabs; deepen Pay (split, step-up), Cards (Apple Pay), Grow (vault detail), Rewards redemption; wire Riz to a real Claude API via a backend proxy; add persistence.
- Legal copy is PROTOTYPE — needs Raiffeisen legal review.
