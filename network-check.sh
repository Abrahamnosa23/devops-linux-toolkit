#!/usr/bin/env bash
# network-check.sh <hostname-or-ip> [port]
# Exit codes: 0 = success, 1 = network failure, 2 = invalid input
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${LOG_DIR:-$SCRIPT_DIR/logs}"
LOG_FILE="$LOG_DIR/toolkit.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
  printf '%s [network-check] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

usage() {
  echo "Usage: $0 <hostname-or-ip> [port]" >&2
  echo "  port  optional TCP port, 1-65535" >&2
}

invalid() {
  echo "ERROR: $1" >&2
  usage
  log "Invalid input: $1"
  exit 2
}

valid_host() {
  local h="$1" o
  [[ -n "$h" && ${#h} -le 253 ]] || return 1
  if [[ "$h" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then          # IPv4
    local IFS=.
    for o in $h; do (( 10#$o <= 255 )) || return 1; done
    return 0
  fi
  if [[ "$h" == *:* ]]; then                                      # IPv6
    [[ "$h" =~ ^[0-9A-Fa-f:.]+$ ]]
    return
  fi
  [[ "$h" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$ ]]
}

valid_port() {
  [[ "$1" =~ ^[0-9]{1,5}$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}

[[ $# -ge 1 && $# -le 2 ]] || invalid "expected <hostname-or-ip> and optional [port]"
host="$1"
port="${2:-}"

valid_host "$host" || invalid "invalid hostname or IP address: '$host'"
if [[ -n "$port" ]]; then
  valid_port "$port" || invalid "port must be an integer from 1 to 65535 (got '$port')"
fi

status=0
echo "=== Network check: $host${port:+:$port} ==="
log "Starting network check for host=$host port=${port:-none}"

# 1. Resolve
resolved="$(getent ahosts "$host" 2>/dev/null | awk 'NR==1 {print $1}')"
if [[ -z "$resolved" ]]; then
  echo "Resolution   : FAILED - cannot resolve '$host'"
  log "Resolution failed for $host"
  exit 1
fi
echo "Resolved to  : $resolved"
log "Resolved $host to $resolved"

# 2. Basic connectivity (ICMP; informational because many networks block ping)
if command -v ping >/dev/null 2>&1; then
  if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
    echo "Ping         : OK"
    log "Ping to $host succeeded"
  else
    echo "Ping         : no reply (ICMP may be blocked)"
    log "Ping to $host got no reply"
  fi
else
  echo "Ping         : skipped (ping not installed)"
  log "ping command not available"
fi

# 3. Interfaces
echo "--- Network interfaces ---"
if command -v ip >/dev/null 2>&1; then
  ip -brief address 2>/dev/null || ip address
elif command -v ifconfig >/dev/null 2>&1; then
  ifconfig
else
  ls /sys/class/net 2>/dev/null || echo "interface information unavailable"
fi
log "Displayed network interface information"

# 4. Optional TCP check
if [[ -n "$port" ]]; then
  echo "--- TCP check ---"
  if timeout 3 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
    echo "TCP $port     : OPEN"
    log "TCP $host:$port is open"
  else
    echo "TCP $port     : CLOSED or unreachable"
    log "TCP $host:$port is closed/unreachable"
    status=1
  fi
fi

log "Network check finished with exit code $status"
exit $status
