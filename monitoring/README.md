# Lab Health Check

This Bash script gives me a quick way to check the status of the services running in my home lab.

## What It Checks

- SSH, Nginx, PostgreSQL 18, and BIND9 service status
- Whether ports 22, 53, 80, and 5432 are listening
- Whether PostgreSQL is listening on the lab network address
- Root filesystem disk usage
- Recent error-level journal entries for the monitored services

## Services Checked

| Service | Purpose |
|---|---|
| SSH | Remote administration |
| Nginx | Web server |
| PostgreSQL 18 | Database server |
| BIND9 (service name `named`) | Internal DNS |

On Ubuntu, `bind9` is an alias for the real service name `named`, and the journal logs under `named`. The script uses `named` so that BIND9 errors in the journal are actually found.

## Network Ports Checked

| Port | Service |
|---|---|
| 22 | SSH |
| 53 | DNS |
| 80 | HTTP |
| 5432 | PostgreSQL |

## Error Checking

The script uses `journalctl` to look for error-level messages from the monitored services within the previous hour.

Example output:

    ssh: No recent errors
    nginx: No recent errors
    postgresql@18-main: No recent errors
    named: No recent errors

## Running the Script

The script is located at:

    monitoring/lab-health-check.sh

It can be run directly from a copy of the repository:

    sudo bash monitoring/lab-health-check.sh

Optionally, install it to `/usr/local/bin` so it can be run from anywhere:

    sudo install -m 755 monitoring/lab-health-check.sh /usr/local/bin/lab-health-check.sh
    sudo lab-health-check.sh

The script exits with status 0 when everything is healthy and 1 if any check fails.

The script was tested in my home lab after configuring Nginx, PostgreSQL, BIND9, SSH, and the firewall.
