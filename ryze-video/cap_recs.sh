#!/bin/bash
# Record real motion clips from the booted sim (background recordVideo + kill -INT to finalize).
b="al.raiffeisen.ryze"
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/captures"
s(){ perl -e 'select(undef,undef,undef,shift)' "$1"; }
xcrun simctl status_bar booted override --time '9:41' --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1

rec(){ # rec OUTFILE SECS KEY=VAL ...   (KEY=VAL may contain spaces if quoted at call site)
  local name="$1"; local out="$BASE/captures/$1"; local secs="$2"; shift 2
  local -a envs=(SIMCTL_CHILD_RYZE_LANG=en SIMCTL_CHILD_RYZE_APPEARANCE=dark)
  local kv; for kv in "$@"; do envs+=("SIMCTL_CHILD_$kv"); done
  xcrun simctl io booted recordVideo --codec h264 --force "$out" >/dev/null 2>&1 &
  local rp=$!
  s 1.0                                   # recorder warm-up
  env "${envs[@]}" xcrun simctl launch --terminate-running-process booted "$b" >/dev/null 2>&1
  s "$secs"                               # capture the motion
  kill -INT "$rp" 2>/dev/null
  wait "$rp" 2>/dev/null
  printf '  %-10s %ss\n' "$name" "$secs"
}

echo "Recording motion clips..."
rec riz.mp4  9 RYZE_HOME=1 RYZE_TAB=3 "RYZE_ASK=How am I spending this month?"
rec seal.mp4 6 RYZE_PHASE=success
rec home.mp4 5 RYZE_HOME=1 RYZE_TAB=0
echo "Done."
for f in "$BASE/captures/"*.mp4; do printf '%s  ' "$(basename "$f")"; ffprobe -v error -show_entries format=duration:stream=width,height -of csv=p=0:s=x "$f" 2>/dev/null | tr '\n' ' '; echo; done
