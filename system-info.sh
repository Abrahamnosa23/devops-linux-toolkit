#!/usr/bin/env bash
# system-info.sh - display system information (all values read at runtime)
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${LOG_DIR:-$SCRIPT_DIR/logs}"
LOG_FILE="$LOG_DIR/toolkit.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
  printf '%s [system-info] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

os_name() {
  if [[ -r /etc/os-release ]]; then
    ( . /etc/os-release; echo "${PRETTY_NAME:-${NAME:-unknown}}" )
  else
    uname -s
  fi
}

uptime_info() {
  if uptime -p >/dev/null 2>&1; then
    uptime -p
  elif [[ -r /proc/uptime ]]; then
    awk '{s=int($1); printf "up %d days, %d hours, %d minutes\n", s/86400, (s%86400)/3600, (s%3600)/60}' /proc/uptime
  else
    uptime
  fi
}

cpu_info() {
  local model cores
  if [[ -r /proc/cpuinfo ]]; then
    model="$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')"
  fi
  [[ -z "${model:-}" ]] && model="$(lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^ +/,"",$2); print $2; exit}')"
  cores="$(nproc 2>/dev/null || echo '?')"
  echo "${model:-unknown} (${cores} core(s))"
}

mem_info() {
  if command -v free >/dev/null 2>&1; then
    free -h | awk '/^Mem:/ {print "total " $2 ", used " $3 ", free " $4 ", available " $7}'
  elif [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "total %d MB, available %d MB\n", t/1024, a/1024}' /proc/meminfo
  else
    echo "unavailable"
  fi
}

log "Collecting system information"
echo "=============== System Information ==============="
echo "Hostname          : $(hostname 2>/dev/null || uname -n)"
echo "Current user      : $(whoami 2>/dev/null || id -un)"
echo "Date/Time         : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Operating system  : $(os_name)"
echo "Kernel version    : $(uname -r)"
echo "Uptime            : $(uptime_info)"
echo "CPU               : $(cpu_info)"
echo "Memory            : $(mem_info)"
echo "Working directory : $(pwd)"
echo "=================================================="
log "System information displayed successfully"
exit 0
