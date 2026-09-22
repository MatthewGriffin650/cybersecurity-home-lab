# Cybersecurity Home Lab

I built this home lab to get more hands-on experience with Linux, networking,
system administration, and cybersecurity.

The lab uses VMware Workstation with a Kali Linux VM and an Ubuntu Server VM.
I used Kali as my security/testing machine and Ubuntu as the server running
the services I wanted to practice configuring and securing.

## What I Built

- Kali Linux security/testing VM
- Ubuntu Server VM
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

## Lab Setup

```text
                    Kali Linux
                 Security Workstation
                        |
                        |
                 VMware Host-Only
                     Network
                        |
                        v
                  Ubuntu Server
                        |
          +-------------+-------------+
          |             |             |
         DNS           HTTP       PostgreSQL
        BIND9          Nginx          |
          |             |             |
    intranet.lab    Web Portal       labdb
```

The two VMs communicate over an isolated host-only VMware network. Kali also
has separate internet connectivity for updates and security tools.

I kept the server environment isolated from my normal home network so I could
test configurations in a controlled environment.

## Services

| Service | Port | What I Used It For |
|---|---:|---|
| SSH | 22 | Remote administration of Ubuntu |
| BIND9 | 53 | Internal DNS |
| Nginx | 80 | Internal web server |
| PostgreSQL | 5432 | Database service |

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

## Nginx

I set up Nginx as an internal web server and created a simple web portal for
the lab.

I also made several basic hardening changes:

- Disabled Nginx server version exposure
- Added `X-Content-Type-Options: nosniff`
- Added `X-Frame-Options: SAMEORIGIN`
- Added `Referrer-Policy: strict-origin-when-cross-origin`
- Used `try_files` to prevent invalid file requests

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

## Firewall

I configured UFW on Ubuntu with a default-deny incoming policy.

Only the services needed by the lab were allowed through the firewall:

- SSH
- HTTP
- DNS
- PostgreSQL

The PostgreSQL rule was further restricted so that only the Kali machine
could connect to the database.

This gave me practical experience with controlling network access based on
both ports and source addresses.

## Logging and Monitoring

I used `systemd` and `journald` to manage and troubleshoot the services on
Ubuntu.

I also created a Bash health-check script that checks the status of the
important services and looks for recent errors in the system journal.

The script checks:

- Nginx
- PostgreSQL
- BIND9

This gave me some experience with basic Linux service monitoring and
automation.

## Backups

I created a backup directory for the lab and made separate backups for
important configuration and application data.

The backups included:

- Nginx configuration and website files
- PostgreSQL database
- BIND9 configuration
- Monitoring configuration

For PostgreSQL, I used `pg_dump` to create a custom-format database dump and
verified the dump with `pg_restore`.

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
- PostgreSQL backups could be inspected and verified
