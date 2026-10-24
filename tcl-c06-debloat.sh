#!/usr/bin/env bash
# Debloat helper for a TCL "Smart TV" (device C06, Android 11), built from its own package list.
# Usage: ./tcl-c06-debloat.sh <TV_IP> status | free | reinstall | disable | restore
#   status     show free space on the TV
#   free       back up, then remove the apps in REMOVE below, one at a time, and STOP as soon
#              as free space reaches TARGET_KB (so it removes as little as possible)
#   reinstall  put back everything removed by "free" from the APK backups in ./backup
#   disable    disable the apps in DISABLE below (reversible, does NOT free space)
#   restore    re-enable everything "disable" turned off
# Edit the lists below first. A leading "#" skips a line.

set -u
export MSYS_NO_PATHCONV=1   # stop Git Bash / MSYS rewriting /data into a Windows path

IP="${1:-}"; MODE="${2:-status}"
[ -n "$IP" ] || { sed -n '2,11p' "$0"; exit 1; }
SER="$IP:5555"
adb connect "$SER" >/dev/null 2>&1
A() { adb -s "$SER" "$@"; }
A get-state >/dev/null 2>&1 || { echo "TV not reachable at $SER. Check the IP and accept the prompt on the TV."; exit 1; }

# The installer keeps ~10% of this TV's 2.7 GB /data free, plus the app itself.
TARGET_KB=300000   # about 293 MB free

# Removed only until TARGET_KB is free, in this order (least useful first).
# These are the user-installed apps on this TV. Uncomment the last two only if nobody uses them.
REMOVE=(
  com.tcl.movieark            # TCL movie app, ~57 MB
  com.tcl.gallery             # ~41 MB
  com.tcl.browser             # ~35 MB
  # com.spotify.tv.android    # ~9 MB, can be reinstalled from the Play Store
  # com.yablio.sendfilestotv  # Send Files to TV
)

# Reversible, frees no space. Pre-installed promo / unused apps from this TV's package list.
DISABLE=(
  au.com.stan.and             # Stan (Australian streaming)
  tv.wuaki.apptv              # Rakuten TV
  com.tcl.esticker            # TCL e-sticker (retail promo)
  com.google.android.play.games
)

free_kb() { A shell df -k /data | tr -d '\r' | tail -1 | awk '{print $4}'; }
mb() { echo $(( $1 / 1024 )); }
installed() { A shell pm list packages | tr -d '\r' | grep -qx "package:$1"; }

case "$MODE" in
  status)
    echo "Free space on the TV: $(mb "$(free_kb)") MB (target $(mb $TARGET_KB) MB)"
    ;;

  free)
    echo "Free space now: $(mb "$(free_kb)") MB (target $(mb $TARGET_KB) MB)"
    echo "Will back up and remove, in this order, until the target is reached:"
    for p in "${REMOVE[@]}"; do echo "  $p"; done
    read -r -p "Type YES to continue: " ok; [ "$ok" = YES ] || { echo "Cancelled."; exit 0; }
    mkdir -p backup
    for p in "${REMOVE[@]}"; do
      if [ "$(free_kb)" -ge "$TARGET_KB" ]; then echo "Target reached, stopping."; break; fi
      installed "$p" || { echo "skip (not installed): $p"; continue; }
      mkdir -p "backup/$p"
      for path in $(A shell pm path "$p" | tr -d '\r' | sed 's/^package://'); do
        A pull "$path" "backup/$p/" >/dev/null 2>&1
      done
      if ! ls "backup/$p"/*.apk >/dev/null 2>&1; then echo "backup failed, NOT removing $p"; continue; fi
      echo "$p -> $(A shell pm uninstall --user 0 "$p" | tr -d '\r')   (APK saved in backup/$p)"
      echo "$p" >> removed.log
    done
    echo "Free space now: $(mb "$(free_kb)") MB (target $(mb $TARGET_KB) MB)"
    ;;

  reinstall)
    [ -f removed.log ] || { echo "removed.log not found, nothing to reinstall."; exit 0; }
    sort -u removed.log | while IFS= read -r p; do
      [ -n "$p" ] && ls "backup/$p"/*.apk >/dev/null 2>&1 || { echo "no backup for $p"; continue; }
      echo "$p -> $(A install-multiple -r "backup/$p"/*.apk 2>&1 | tail -1)"
    done
    ;;

  disable)
    for p in "${DISABLE[@]}"; do
      installed "$p" || { echo "skip (not installed): $p"; continue; }
      out="$(A shell pm disable-user --user 0 "$p" 2>&1 | tr -d '\r')"
      echo "$p -> $out"
      echo "$out" | grep -qi "disabled" && echo "$p" >> disabled.log
    done
    echo "Undo with: ./tcl-c06-debloat.sh $IP restore"
    ;;

  restore)
    [ -f disabled.log ] || { echo "disabled.log not found, nothing to restore."; exit 0; }
    sort -u disabled.log | while IFS= read -r p; do
      [ -n "$p" ] && echo "$p -> $(A shell pm enable "$p" 2>&1 | tr -d '\r')"
    done
    mv disabled.log "disabled.log.restored.$(date +%s)"
    ;;

  *) sed -n '2,11p' "$0"; exit 1 ;;
esac
