#!/bin/bash
# Usage: sim-cpu.sh <UDID> <label> [seconds]
# Average CPU (% of one core) of the example app and the simulator's
# backboardd over the window, from their cumulative CPU time. Boot only one
# simulator: the first simulator backboardd found is used.
udid=$1
label=$2
secs=${3:-30}
out=/tmp/maps-e2e/results.tsv
mkdir -p /tmp/maps-e2e

app=$(pgrep -f "Devices/$udid/.*\.app/LuggMapsExample" | head -1)
bb=$(pgrep -f 'simruntime.*/backboardd$' | head -1)
if [ -z "$app" ] || [ -z "$bb" ]; then
  echo "app ($app) or backboardd ($bb) not found" >&2
  exit 1
fi

# ps prints MM:SS.ss or H:MM:SS.ss
cpu() { ps -o time= -p "$1" | awk -F'[:.]' '{ if (NF == 4) print $1*3600 + $2*60 + $3 + $4/100; else print $1*60 + $2 + $3/100 }'; }

a0=$(cpu "$app"); b0=$(cpu "$bb")
sleep "$secs"
a1=$(cpu "$app"); b1=$(cpu "$bb")

awk -v l="$label" -v a0="$a0" -v a1="$a1" -v b0="$b0" -v b1="$b1" -v s="$secs" \
  'BEGIN { printf "%s\tapp %.1f%%\tbackboardd %.1f%%\n", l, (a1-a0)/s*100, (b1-b0)/s*100 }' |
  tee -a "$out"
