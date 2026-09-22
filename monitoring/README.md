# Lab Health Check

This Bash script gives me a quick way to check the status of the services running in my home lab.

## What It Checks

The script checks:

- Nginx service status
- PostgreSQL 18 service status
- BIND9 service status
- Listening network ports
- Root filesystem disk usage
- Recent errors for the monitored services

## Services Checked

| Service | Purpose |
|---|---|
| Nginx | Web server |
| PostgreSQL 18 | Database server |
| BIND9 | Internal DNS |

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

    nginx: No recent errors
    postgresql@18-main: No recent errors
    bind9: No recent errors

## Running the Script

The script is located at:

    monitoring/lab-health-check.sh

On the Ubuntu Server VM, it can be run with:

    sudo /usr/local/bin/lab-health-check.sh

The script was tested in my home lab after configuring Nginx, PostgreSQL, BIND9, SSH, and the firewall.
