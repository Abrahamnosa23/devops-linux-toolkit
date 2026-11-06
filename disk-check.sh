#!/usr/bin/env bash
# disk-check.sh <threshold 1-100> [path]
# Exit codes: 0 = below threshold, 1 = at/above threshold or runtime failure, 2 = invalid input
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${LOG_DIR:-$SCRIPT_DIR/logs}"
LOG_FILE="$LOG_DIR/toolkit.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
  printf '%s [disk-check] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

usage() {
  echo "Usage: $0 <threshold 1-100> [path]" >&2
  echo "  threshold  integer from 1 to 100 (percent)" >&2
  echo "  path       filesystem path to check (default: /)" >&2
}

invalid() {
  echo "ERROR: $1" >&2
  usage
  log "Invalid input: $1"
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || invalid "expected 1 or 2 arguments"

threshold="$1"
path="${2:-/}"

[[ "$threshold" =~ ^[0-9]+$ ]] || invalid "threshold must be an integer (got '$threshold')"
[[ ${#threshold} -le 3 ]] || invalid "threshold must be between 1 and 100"
threshold=$((10#$threshold))
(( threshold >= 1 && threshold <= 100 )) || invalid "threshold must be between 1 and 100"
[[ -e "$path" ]] || invalid "path does not exist: $path"

usage_pct="$(df -P "$path" 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
if ! [[ "$usage_pct" =~ ^[0-9]+$ ]]; then
  echo "ERROR: could not determine disk usage for $path" >&2
  log "Runtime failure: could not read disk usage for $path"
  exit 1
fi

echo "Path      : $path"
echo "Usage     : ${usage_pct}%"
echo "Threshold : ${threshold}%"
log "Checked $path: usage=${usage_pct}% threshold=${threshold}%"

if (( usage_pct >= threshold )); then
  echo "STATUS: ALERT - disk usage has reached or exceeded the threshold"
  log "ALERT: $path usage ${usage_pct}% >= ${threshold}%"
  exit 1
fi
echo "STATUS: OK - disk usage is below the threshold"
log "OK: $path usage ${usage_pct}% < ${threshold}%"
exit 0
