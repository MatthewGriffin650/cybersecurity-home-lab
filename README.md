# Cybersecurity Home Lab

I built this home lab to get more hands-on experience with Linux, networking,
system administration, and cybersecurity.

The lab uses VMware Workstation with a Kali Linux VM, an Ubuntu Server VM, and
a Splunk SIEM VM. I used Kali as my security/testing machine, Ubuntu as the
server running the services I wanted to practice configuring and securing, and
Splunk to collect and analyze the Ubuntu server's logs.

## What I Built

- Kali Linux security/testing VM
- Ubuntu Server VM
- Splunk Enterprise SIEM VM with a Universal Forwarder, dashboard, and alerts
- Isolated VMware host-only network
- SSH remote administration
- BIND9 internal DNS
- Nginx internal web server
- PostgreSQL database server
- UFW firewall
- Bash service health-check script
- Linux logging and troubleshooting
- Configuration and database backups

## Repository Structure

- `monitoring/` - Service health-check script and monitoring documentation
- `configs/` - Configuration examples and documentation for Nginx, PostgreSQL, UFW, and BIND9
- `backups/` - Documentation for configuration and database backups
- `splunk/` - Splunk SIEM setup, detections, troubleshooting, configs, and screenshots

## Lab Setup

```text
                    Kali Linux (.133)
                 Security Workstation
                        |
                        |
                 VMware Host-Only
                  Network (.240.0/24)
                        |
          +-------------+----------------+
          |                              |
          v                              v
   Ubuntu Server (.132)  ----logs---->  Splunk Server (.134)
          |               9997          index: lab
          |                             dashboard + alerts
   +------+-------+
   |      |       |
  DNS    HTTP  PostgreSQL
 BIND9   Nginx     |
   |      |      labdb
intranet.lab Web Portal
```

The VMs communicate over an isolated host-only VMware network. Kali also
has separate internet connectivity for updates and security tools.

I kept the server environment isolated from my normal home network so I could
test configurations in a controlled environment.

## Services

| Service | Host | Port | What I Used It For |
|---|---|---:|---|
| SSH | Ubuntu | 22 | Remote administration |
| BIND9 | Ubuntu | 53 | Internal DNS |
| Nginx | Ubuntu | 80 | Internal web server |
| PostgreSQL | Ubuntu | 5432 | Database service |
| Splunk Web | Splunk | 8000 | Search, dashboard, and alerts (Kali only) |
| Splunk receiving | Splunk | 9997 | Log input from the Ubuntu forwarder |

## DNS

I configured BIND9 to provide DNS resolution inside the lab.

For example:

```text
intranet.lab → Ubuntu Server
```

This allowed me to access the Nginx server using a hostname instead of
directly entering the server's IP address.

I tested the DNS configuration from Kali using `dig` and then used the
hostname to access the web server.

I also hardened the BIND9 options: zone transfers are refused, the version is
hidden, and queries and recursion are limited to the Kali VM and the server
itself. See `configs/bind9/` for details.

## Nginx

I set up Nginx as an internal web server and created a simple web portal for
the lab.

I also made several basic hardening changes:

- Disabled Nginx server version exposure
- Added `X-Content-Type-Options: nosniff`
- Added `X-Frame-Options: SAMEORIGIN`
- Added `Referrer-Policy: strict-origin-when-cross-origin`

The server block also uses `try_files` to return a 404 for files that don't exist. That is standard static-site behavior rather than a hardening measure.

I tested the Nginx configuration before reloading the service and verified
the web server from Kali using `curl`.

## PostgreSQL

I installed PostgreSQL and created a database called `labdb`.

I configured PostgreSQL so that Kali could connect to the database remotely.
This required changes to the PostgreSQL listening configuration and
`pg_hba.conf`.

I used SCRAM-SHA-256 authentication and restricted PostgreSQL access with
the firewall so that the database was not open to every machine on the lab
network.

I verified the setup by connecting from Kali with `psql` and checking the
current database and user.

The database contains a small sample table, `backup_test`, which exists only so the backup and restore process can be tested against real data. See `backups/README.md` for the restore test.

## Firewall

I configured UFW on Ubuntu with a default-deny incoming policy.

Only the services needed by the lab were allowed through the firewall:

- SSH
- HTTP
- DNS
- PostgreSQL

SSH, DNS, and PostgreSQL are restricted to the Kali VM's address. Only HTTP is open to the rest of the lab network.

The Splunk VM has its own default-deny rules: SSH and the web UI only from Kali, and the forwarder port only from the Ubuntu server.

This gave me practical experience with controlling network access based on
both ports and source addresses.

## Logging and Monitoring

I used `systemd` and `journald` to manage and troubleshoot the services on
Ubuntu.

I also created a Bash health-check script that checks the status of the
important services and looks for recent errors in the system journal.

The script checks:

- SSH, Nginx, PostgreSQL, and BIND9 (`named`) service status
- That ports 22, 53, 80, and 5432 are listening
- That PostgreSQL is listening on the lab network address
- Root filesystem disk usage
- Error-level journal entries from the last hour

It exits with status 0 when everything is healthy and 1 if any check fails.

This gave me some experience with basic Linux service monitoring and
automation.

## Splunk SIEM

To go beyond checking services by hand, I added a dedicated Splunk Enterprise
server. A Universal Forwarder on the Ubuntu server sends five log sources
(SSH auth, Nginx access and error, PostgreSQL, and UFW) to a `lab` index.

On top of that data I built:

- A "Lab Security Overview" dashboard (failed SSH logins, port scan detection, web status codes, PostgreSQL login failures)
- An alert for suspected SSH brute force (5 or more failed passwords from one source)
- An alert for port scans (8 or more distinct blocked ports from one source)

I tested the detections by running `nmap` and repeated failed SSH logins from
Kali, and both alerts triggered. Tuning the port scan threshold and fixing an
installation failure on the Splunk VM are written up in `splunk/`.

See `splunk/README.md` for the full walkthrough, `splunk/detections.md` for the
alert logic, and `splunk/troubleshooting.md` for the problems I solved.

## Backups

I created a backup directory for the lab and made separate backups for
important configuration and application data.

The backups included:

- Nginx configuration and website files
- PostgreSQL database and database roles
- BIND9 configuration
- Monitoring configuration

For PostgreSQL, I used `pg_dump` to create a custom-format database dump and
`pg_dumpall --globals-only` for roles. I tested the restore by loading the dump
into a scratch database and checking the data.

The backups are stored on the same VM they protect, so they cover bad
configuration changes and accidental data loss, but not loss of the VM itself.

The actual backup files are not included in this repository.

## Troubleshooting

One of the more useful parts of building the lab was dealing with things
that did not work correctly the first time.

For example, PostgreSQL initially failed to start after I changed its
configuration.

I used `systemctl` to check the service, then used `journalctl` to find the
error. I inspected the PostgreSQL configuration, found the configuration
problem, corrected it, and restarted the service.

Afterward, I verified that PostgreSQL was running and successfully connected
to it remotely from Kali.

This was good practice for the process of diagnosing a Linux service rather
than just reinstalling it when something goes wrong.

## Testing and Validation

After configuring the lab, I tested the setup from Kali.

I verified:

- Kali could communicate with Ubuntu
- SSH access worked
- `intranet.lab` resolved correctly
- Nginx served the internal website
- PostgreSQL accepted the authorized remote connection
- UFW was enforcing the intended access rules
- The main services were running
- PostgreSQL backups could be restored into a scratch database
- A port scan and failed SSH logins from Kali were logged, shown on the Splunk dashboard, and triggered both alerts
