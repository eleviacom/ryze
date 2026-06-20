#!/bin/bash
# Full-app screenshot library -> ryze-app-screenshots/  (English + dark, clean status bar).
b="al.raiffeisen.ryze"
OUT="/Users/eleviacom/raiffaiesen/ryze-app-screenshots"
mkdir -p "$OUT"
s(){ perl -e 'select(undef,undef,undef,shift)' "$1"; }
xcrun simctl status_bar booted override --time '9:41' --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1

shot(){ # shot OUTNAME KEY=VAL ...
  local name="$1"; shift
  local -a envs=(SIMCTL_CHILD_RYZE_LANG=en SIMCTL_CHILD_RYZE_APPEARANCE=dark)
  local kv; for kv in "$@"; do envs+=("SIMCTL_CHILD_$kv"); done
  env "${envs[@]}" xcrun simctl launch --terminate-running-process booted "$b" >/dev/null 2>&1
  s 2.2
  xcrun simctl io booted screenshot "$OUT/$name" >/dev/null 2>&1
  printf '  %s\n' "$name"
}

echo "Capturing full app -> $OUT"
# --- Onboarding (no RYZE_HOME so the onboarding flow shows) ---
shot 01-onboarding-welcome-1.png   RYZE_SLIDE=0
shot 02-onboarding-welcome-2.png   RYZE_SLIDE=1
shot 03-onboarding-welcome-3.png   RYZE_SLIDE=2
shot 04-onboarding-phone.png       RYZE_PHASE=kyc RYZE_STEP=0
shot 05-onboarding-otp.png         RYZE_PHASE=kyc RYZE_STEP=1
shot 06-onboarding-identity.png    RYZE_PHASE=kyc RYZE_STEP=2
shot 07-onboarding-details.png     RYZE_PHASE=kyc RYZE_STEP=3
shot 08-onboarding-consents.png    RYZE_PHASE=kyc RYZE_STEP=4
shot 09-onboarding-notifications.png RYZE_PHASE=kyc RYZE_STEP=5
shot 10-onboarding-success.png     RYZE_PHASE=success
# --- Main tabs ---
shot 11-home.png                   RYZE_HOME=1 RYZE_TAB=0
shot 12-cards.png                  RYZE_HOME=1 RYZE_TAB=1
shot 13-pay.png                    RYZE_HOME=1 RYZE_TAB=2
shot 14-assistant-riz.png          RYZE_HOME=1 RYZE_TAB=3
shot 15-assistant-riz-answer.png   RYZE_HOME=1 RYZE_TAB=3 RYZE_RIZ=1
shot 16-rewards.png                RYZE_HOME=1 RYZE_TAB=4
# --- Pay flows ---
shot 17-pay-chat-thread.png        RYZE_HOME=1 RYZE_TAB=2 RYZE_THREAD=elsa
shot 18-pay-split-bill.png         RYZE_HOME=1 RYZE_VIEW=split
shot 19-pay-scan.png               RYZE_HOME=1 RYZE_VIEW=scan
shot 20-pay-bank-transfer.png      RYZE_HOME=1 RYZE_VIEW=bank
shot 21-pay-qr.png                 RYZE_HOME=1 RYZE_VIEW=qr
shot 22-exchange.png               RYZE_HOME=1 RYZE_VIEW=exchange
shot 23-analytics.png              RYZE_HOME=1 RYZE_VIEW=analytics
# --- Grow / savings ---
shot 24-grow-savings.png           RYZE_HOME=1 RYZE_VIEW=grow
shot 25-grow-new-goal.png          RYZE_HOME=1 RYZE_VIEW=newgoal
shot 26-grow-goal-detail.png       RYZE_HOME=1 RYZE_VIEW=goaldetail
# --- Card flows ---
shot 27-card-studio.png            RYZE_HOME=1 RYZE_VIEW=cardstudio
shot 28-card-order.png             RYZE_HOME=1 RYZE_VIEW=ordercard
shot 29-card-limit.png             RYZE_HOME=1 RYZE_VIEW=cardlimit
shot 30-card-apple-pay.png         RYZE_HOME=1 RYZE_VIEW=applepay
shot 31-card-virtual.png           RYZE_HOME=1 RYZE_VIEW=vcard
# --- Rewards flows ---
shot 32-rewards-redeem-store.png   RYZE_HOME=1 RYZE_VIEW=redeem
shot 33-rewards-earn.png           RYZE_HOME=1 RYZE_VIEW=earn
shot 34-rewards-coupon.png         RYZE_HOME=1 RYZE_VIEW=coupon
shot 35-plans.png                  RYZE_HOME=1 RYZE_VIEW=plans
# --- Profile / account ---
shot 36-profile.png                RYZE_HOME=1 RYZE_VIEW=profile
shot 37-settings.png               RYZE_HOME=1 RYZE_VIEW=settings
shot 38-search.png                 RYZE_HOME=1 RYZE_VIEW=search
echo "Done."
ls "$OUT"/*.png | wc -l | xargs echo "screenshots:"