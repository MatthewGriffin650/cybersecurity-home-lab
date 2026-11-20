# Detections

This lab collects logs from the Ubuntu server into Splunk and uses two scheduled alerts to detect attacks launched from the Kali VM. All lab logs go into a dedicated index named `lab`.

## Log sources

| Source | Sourcetype | What it shows |
|---|---|---|
| `/var/log/auth.log` | `linux_secure` | SSH logins and failures |
| `/var/log/ufw.log` | `ufw` | Firewall blocks and allowed connections |
| `/var/log/nginx/access.log` | `access_combined` | Web requests and status codes |
| `/var/log/nginx/error.log` | `nginx_error` | Web server errors |
| `/var/log/postgresql/postgresql-18-main.log` | `postgresql` | Database login failures |

Forwarder configuration is in `configs/inputs.conf.example` and `configs/outputs.conf.example`.

## Alert 1: SSH Brute Force Suspected

Fires when a single source has 5 or more failed SSH password attempts in 5 minutes.

```
index=lab source="/var/log/auth.log" "Failed password"
| rex "Failed password for (invalid user )?(?<user>\S+) from (?<src>\S+)"
| stats count by src
| where count >= 5
```

| Setting | Value |
|---|---|
| Type | Scheduled, cron `*/5 * * * *` |
| Time range | Last 5 minutes (`-5m` to `now`) |
| Trigger | Number of results greater than 0, for each result |
| Action | Add to Triggered Alerts |

**Test:** From Kali, I ran `ssh wronguser@192.168.240.132` repeatedly with wrong passwords (five attempts, three password prompts each). The alert appeared in Triggered Alerts after the next scheduled run.

## Alert 2: Port Scan Detected

Fires when a single source hits 8 or more distinct blocked ports in 5 minutes.

```
index=lab sourcetype=ufw "UFW BLOCK"
| rex "SRC=(?<src>\S+).*DPT=(?<dpt>\d+)"
| stats dc(dpt) as ports_hit by src
| where ports_hit >= 8
```

| Setting | Value |
|---|---|
| Type | Scheduled, cron `*/5 * * * *` |
| Time range | Last 5 minutes (`-5m` to `now`) |
| Trigger | Number of results greater than 0, for each result |
| Action | Add to Triggered Alerts |

**Test:** From Kali, `nmap -Pn -p 1-1000 192.168.240.132`.

**Threshold tuning:** I first set the threshold to 15 distinct ports, assuming a 1,000-port scan would block hundreds. It did not fire. Searching the data showed only 11 distinct blocked ports for that single scan. (The dashboard bar shows 26 because it adds up every scan and probe from Kali over the whole 24-hour window). UFW rate-limits its logging, so only a short burst of blocked packets is written to `ufw.log`. I lowered the threshold to 8, which sits below the observed 11 and still far above normal traffic (normal connections never hit blocked ports).

**Result:** After lowering the threshold to 8, the alert fired at 19:15 UTC on the next scheduled run (screenshot 08).

## Dashboard: Lab Security Overview

The dashboard source is in `configs/lab-security-overview.xml`. All panels use a shared time picker.

| Panel | Search purpose |
|---|---|
| Failed SSH Logins | Failed password attempts by source IP and username |
| Port Scan Detection | Distinct blocked ports per source (bar chart) |
| Web Server Status Codes | Count of HTTP status codes (pie chart) |
| PostgreSQL Login Failures | Bad passwords and `pg_hba.conf` rejections |

## Limitations and notes

- **Alert latency:** Alerts run every 5 minutes, so detection can take up to about 5 minutes after an event, plus a short forwarding delay.
- **Licensing:** The Splunk Enterprise trial license supports scheduled alerts. After the trial expires, the instance falls back to a free tier that does not run scheduled alerts. Dashboards and manual searches still work.
- **Time zones:** Server logs and Splunk use UTC. The Kali terminal shows Eastern time, so timestamps differ by five hours.
- **Clock drift:** The VMs are not time-synchronized, so event times can differ by a few seconds across machines.
- **UFW log level:** `ufw logging medium` also writes allowed connections, which adds noise. `low` would log blocks only.

## What I would add next

- Time-sync all lab VMs with NTP.
- Alert on repeated PostgreSQL authentication failures.
- Alert on web scanning (many 404s from one source).
- Forward the Splunk VM's own `auth.log`.
