# Assignment 1 – Linux, Bash & Networking Diagnostic Toolkit

A small Bash toolkit that collects system information, checks disk usage and performs basic network checks.

## Requirements
Linux, Bash 4+, and standard tools (`df`, `awk`, `getent`, `ip`, `ping`, `timeout`). No internet is required for the tests (`localhost` is used).

## Setup
```bash
git clone <your-repository-url>
cd <repository>
chmod +x *.sh
```

## Usage
| Script | Command | Description |
|---|---|---|
| `system-info.sh` | `./system-info.sh` | Hostname, user, date/time, OS, kernel, uptime, CPU, memory, working directory |
| `disk-check.sh` | `./disk-check.sh <threshold> [path]` | Threshold 1-100, default path `/` |
| `network-check.sh` | `./network-check.sh <host-or-ip> [port]` | Resolves host, pings, lists interfaces, optional TCP check |

### Exit codes
| Script | 0 | 1 | 2 |
|---|---|---|---|
| `disk-check.sh` | usage below threshold | usage >= threshold / runtime failure | invalid input |
| `network-check.sh` | all checks passed | resolution or TCP failure | invalid host/port/arguments |

### Examples
```bash
./system-info.sh
./disk-check.sh 80
./disk-check.sh 90 /home
./network-check.sh localhost
./network-check.sh 8.8.8.8 53
```

## Logging
Every script appends timestamped entries to `logs/toolkit.log`, e.g.
`2026-10-30 10:15:02 [disk-check] Checked /: usage=42% threshold=80%`.
Set `LOG_DIR=/some/path` to change the log directory. `*.log` files are git-ignored; `logs/.gitkeep` keeps the folder in Git.

## Testing
```bash
chmod +x grade.sh *.sh
./grade.sh
```
Manual checks:
```bash
./disk-check.sh 0; echo $?        # 2
./disk-check.sh abc; echo $?      # 2
./network-check.sh; echo $?       # 2
./network-check.sh localhost 0; echo $?      # 2
./network-check.sh localhost 65536; echo $?  # 2
```

## Assumptions
- Ping failure is informational (ICMP is often blocked); the result is decided by name resolution and, if given, the TCP check.
- Only Linux is supported.
- No secrets are stored in this repository.

## Git workflow
Work was done on a `feature/...` branch with small commits and merged into `main`.
