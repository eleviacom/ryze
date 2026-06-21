#!/bin/bash
# Full-app screenshot library -> screenshots/  (English, dark, clean 9:41 status bar).
# Drives the app entirely through its built-in RYZE_* launch-env hooks (see RyzeApp.swift
# RootView, OnboardingModel, Game/Bank init). Rebuild + reinstall the app first so the
# shots reflect current source. Onboarding steps map to OnboardingModel.steps indices.
set -euo pipefail
b="al.raiffeisen.ryze"
OUT="$(cd "$(dirname "$0")" && pwd)"
KYC="RYZE_PHASE=kyc RYZE_PREFILL=1 RYZE_FLAGS=1 RYZE_CONSENT=1 RYZE_PLAN=lift"
s(){ perl -e 'select(undef,undef,undef,shift)' "$1"; }
xcrun simctl status_bar booted override --time '9:41' --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1 || true

shot(){ # shot OUTNAME KEY=VAL ...
  local name="$1"; shift
  local -a envs=(SIMCTL_CHILD_RYZE_LANG=en SIMCTL_CHILD_RYZE_APPEARANCE=dark)
  local kv; for kv in "$@"; do envs+=("SIMCTL_CHILD_$kv"); done
  env "${envs[@]}" xcrun simctl launch --terminate-running-process booted "$b" >/dev/null 2>&1
  s 2.5
  xcrun simctl io booted screenshot "$OUT/$name" >/dev/null 2>&1
  printf '  %s\n' "$name"
}

# Same as shot() but waits longer — the discovery map needs MapKit street tiles to load over the network.
shotmap(){
  local name="$1"; shift
  local -a envs=(SIMCTL_CHILD_RYZE_LANG=en SIMCTL_CHILD_RYZE_APPEARANCE=dark)
  local kv; for kv in "$@"; do envs+=("SIMCTL_CHILD_$kv"); done
  env "${envs[@]}" xcrun simctl launch --terminate-running-process booted "$b" >/dev/null 2>&1
  s 5.0
  xcrun simctl io booted screenshot "$OUT/$name" >/dev/null 2>&1
  printf '  %s\n' "$name"
}

echo "Capturing full app -> $OUT"
# --- Onboarding: welcome carousel (no RYZE_HOME so the onboarding flow shows) ---
shot 01-onboarding-welcome-1.png      RYZE_SLIDE=0
shot 02-onboarding-welcome-2.png      RYZE_SLIDE=1
shot 03-onboarding-welcome-3.png      RYZE_SLIDE=2
# --- Onboarding: KYC steps (index = OnboardingModel.steps order) ---
shot 04-onboarding-phone.png          $KYC RYZE_STEP=0
shot 05-onboarding-otp.png            $KYC RYZE_STEP=1
shot 06-onboarding-passcode.png       $KYC RYZE_STEP=2
shot 07-onboarding-faceid.png         $KYC RYZE_STEP=3
shot 08-onboarding-details.png        $KYC RYZE_STEP=4
shot 09-onboarding-address.png        $KYC RYZE_STEP=5
shot 10-onboarding-usage.png          $KYC RYZE_STEP=6
shot 11-onboarding-identity.png       $KYC RYZE_STEP=7
shot 12-onboarding-consents.png       $KYC RYZE_STEP=8
shot 13-onboarding-notifications.png  $KYC RYZE_STEP=9
shot 14-onboarding-plan.png           $KYC RYZE_STEP=10
shot 15-onboarding-success.png        RYZE_PHASE=success RYZE_PLAN=lift
# --- First-run welcome challenges (slides up the first time you enter the app) ---
shot 16-welcome-challenges.png        RYZE_HOME=1 RYZE_WELCOME=1
# --- Main tabs ---
shot 17-home.png                      RYZE_HOME=1 RYZE_TAB=0
shot 18-cards.png                     RYZE_HOME=1 RYZE_TAB=1 RYZE_VCARD=1 RYZE_REVEAL=1
shot 19-pay.png                       RYZE_HOME=1 RYZE_TAB=2
shot 20-assistant-riz.png             RYZE_HOME=1 RYZE_TAB=3
shot 21-assistant-riz-answer.png      RYZE_HOME=1 RYZE_TAB=3 RYZE_RIZ=1
shot 22-rewards.png                   RYZE_HOME=1 RYZE_TAB=4
# --- Pay flows ---
shot 23-pay-chat-thread.png           RYZE_HOME=1 RYZE_TAB=2 RYZE_THREAD=elsa
shot 24-pay-split-bill.png            RYZE_HOME=1 RYZE_VIEW=split
shot 25-pay-scan.png                  RYZE_HOME=1 RYZE_VIEW=scan
shot 26-pay-bank-transfer.png         RYZE_HOME=1 RYZE_VIEW=bank
shot 27-pay-qr.png                    RYZE_HOME=1 RYZE_VIEW=qr
# --- Add money (methods + ATM map) ---
shot 28-add-money.png                 RYZE_HOME=1 RYZE_VIEW=addmoney
shot 29-atm-map.png                   RYZE_HOME=1 RYZE_VIEW=atm
# --- Money ---
shot 30-exchange.png                  RYZE_HOME=1 RYZE_VIEW=exchange
shot 31-analytics.png                 RYZE_HOME=1 RYZE_VIEW=analytics
# --- Grow / savings ---
shot 32-grow-savings.png              RYZE_HOME=1 RYZE_VIEW=grow
shot 33-grow-new-goal.png             RYZE_HOME=1 RYZE_VIEW=newgoal
shot 34-grow-goal-detail.png          RYZE_HOME=1 RYZE_VIEW=goaldetail
# --- Card flows ---
shot 35-card-studio.png               RYZE_HOME=1 RYZE_VIEW=cardstudio
shot 36-card-order.png                RYZE_HOME=1 RYZE_VIEW=ordercard
shot 37-card-limit.png                RYZE_HOME=1 RYZE_VIEW=cardlimit
shot 38-card-apple-pay.png            RYZE_HOME=1 RYZE_VIEW=applepay
shot 39-card-virtual.png              RYZE_HOME=1 RYZE_VIEW=vcard RYZE_REVEAL=1
# --- Rewards flows ---
shot 40-rewards-redeem-store.png      RYZE_HOME=1 RYZE_VIEW=redeem
shot 41-rewards-earn.png              RYZE_HOME=1 RYZE_VIEW=earn
shot 42-rewards-coupon.png            RYZE_HOME=1 RYZE_VIEW=coupon
shot 43-plans.png                     RYZE_HOME=1 RYZE_VIEW=plans RYZE_PLAN=surge
# --- Profile / account ---
shot 44-profile.png                   RYZE_HOME=1 RYZE_VIEW=profile
shot 45-settings.png                  RYZE_HOME=1 RYZE_VIEW=settings
shot 46-search.png                    RYZE_HOME=1 RYZE_VIEW=search
# --- Gamification — unlockable discovery map (real Tirana streets + fog of war) ---
shotmap 47-discovery-map.png          RYZE_HOME=1 RYZE_VIEW=map
shotmap 48-discovery-map-unlocked.png RYZE_HOME=1 RYZE_MAP=1 RYZE_VIEW=map
xcrun simctl status_bar booted clear >/dev/null 2>&1 || true
echo "Done. screenshots: $(ls "$OUT"/*.png 2>/dev/null | wc -l | tr -d ' ')"
