#!/bin/bash
# Deterministic screenshot capture from the booted iPhone sim.
# Uses RYZE_* deep-links via SIMCTL_CHILD_ passthrough. perl for settle delay (no `sleep`/`timeout` dep).
b="al.raiffeisen.ryze"
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/screens"
s(){ perl -e 'select(undef,undef,undef,shift)' "$1"; }

# keep the status bar clean (9:41, full battery/signal) across relaunches
xcrun simctl status_bar booted override --time '9:41' --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1

shot(){ # shot OUTFILE KEY=VAL ...
  local name="$1"; local out="$BASE/screens/$1"; shift
  local pfx=" SIMCTL_CHILD_RYZE_LANG=en SIMCTL_CHILD_RYZE_APPEARANCE=dark"
  for kv in "$@"; do pfx="$pfx SIMCTL_CHILD_$kv"; done
  env $pfx xcrun simctl launch --terminate-running-process booted "$b" >/dev/null 2>&1
  s 2.2
  xcrun simctl io booted screenshot "$out" >/dev/null 2>&1
  printf '  %-18s [%s]\n' "$name" "$*"
}

echo "Capturing screenshots..."
shot welcome.png    RYZE_SLIDE=0
shot identity.png   RYZE_PHASE=kyc RYZE_STEP=2
shot home.png       RYZE_HOME=1 RYZE_TAB=0
shot cards.png      RYZE_HOME=1 RYZE_TAB=1
shot cardstudio.png RYZE_VIEW=cardstudio
shot pay.png        RYZE_HOME=1 RYZE_TAB=2
shot thread.png     RYZE_HOME=1 RYZE_TAB=2 RYZE_THREAD=elsa
shot split.png      RYZE_VIEW=split
shot rewards.png    RYZE_HOME=1 RYZE_TAB=4
shot coupon.png     RYZE_VIEW=coupon
shot analytics.png  RYZE_VIEW=analytics
shot rizanswer.png  RYZE_HOME=1 RYZE_TAB=3 RYZE_RIZ=1
echo "Done. Files:"
ls -la "$BASE/screens/"*.png 2>/dev/null | awk '{print $5, $NF}'
