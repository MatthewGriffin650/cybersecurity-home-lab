# BIND9 DNS Configuration

## Overview

BIND9 is the DNS server used in this home lab.

I configured BIND9 on the Ubuntu Server VM to provide DNS resolution for the internal lab domain. This allows the Kali Linux VM to access the internal web server using a hostname instead of an IP address.

The main internal hostname used by the lab is:

    intranet.lab

The hostname resolves to the Ubuntu Server's lab address:

    192.168.240.132

### Lab Setup

- DNS server: Ubuntu Server
- DNS client: Kali Linux
- DNS server IP: `192.168.240.132`
- Internal domain: `intranet.lab`
- DNS port: `53`

---

## Check BIND9 Status

Check whether BIND9 is running:

    sudo systemctl status bind9

Check whether the service is active:

    systemctl is-active bind9

Start BIND9:

    sudo systemctl start bind9

Stop BIND9:

    sudo systemctl stop bind9

Restart BIND9:

    sudo systemctl restart bind9

Reload the configuration:

    sudo systemctl reload bind9

---

## BIND9 Configuration

The main BIND9 configuration directory is:

    /etc/bind/

List the configuration files:

    ls /etc/bind/

The local zone configuration is stored in:

    /etc/bind/named.conf.local

Edit the zone configuration with:

    sudo nano /etc/bind/named.conf.local

The `intranet.lab` zone was configured as a master zone:

    zone "intranet.lab" {
        type master;
        file "/etc/bind/db.intranet.lab";
    };

---

## DNS Zone File

The zone file is:

    /etc/bind/db.intranet.lab

Edit the zone file with:

    sudo nano /etc/bind/db.intranet.lab

The zone file contains the DNS records for the internal `intranet.lab` domain.

The configured records are:

    $TTL 604800
    @ IN SOA ns1.intranet.lab. admin.intranet.lab. (
    2026083101
    604800
    86400
    2419200
    604800 )
    @ IN NS ns1.intranet.lab.
    ns1 IN A 192.168.240.132
    @ IN A 192.168.240.132
    www IN A 192.168.240.132

### DNS Records

The important records are:

| Record | Address |
|---|---|
| `ns1.intranet.lab` | `192.168.240.132` |
| `intranet.lab` | `192.168.240.132` |
| `www.intranet.lab` | `192.168.240.132` |

The `A` records point the hostnames to the Ubuntu Server, where Nginx is running.

---

## SOA Serial Number

The zone's SOA record contains a serial number:

    2026083101

The serial number identifies the current version of the zone data.

When making future changes to the zone file, the serial number should be increased so that DNS servers can recognize that the zone has been updated.

---

## Testing DNS from Kali

DNS resolution can be tested from Kali with:

    dig intranet.lab

A shorter result can be displayed with:

    dig +short intranet.lab

The expected result is:

    192.168.240.132

The hostname can also be tested with:

    nslookup intranet.lab

The `www` record can be tested with:

    dig +short www.intranet.lab

---

## Testing the Web Server Through DNS

After confirming DNS resolution, the Nginx server can be tested using the hostname:

    curl http://intranet.lab

This verifies both DNS resolution and HTTP connectivity to the Nginx server.

The request should resolve `intranet.lab` to the Ubuntu Server and return the internal web page.

---

## Check Listening DNS Ports

Check which addresses and ports BIND9 is listening on:

    sudo ss -tulpn | grep ':53'

This was also included in the home lab health-check script.

The script checks that the DNS service is active and that port `53` is listening.

---

## Firewall Configuration

UFW allows DNS traffic to reach the BIND9 service:

    sudo ufw allow 53

Check the firewall configuration:

    sudo ufw status verbose

DNS access is allowed through the firewall for the lab environment.

---

## Validate BIND9 Configuration

Before restarting BIND9 after making configuration changes, check the configuration syntax with:

    sudo named-checkconf

The zone file can be checked with:

    sudo named-checkzone intranet.lab /etc/bind/db.intranet.lab

If the checks complete successfully, reload BIND9:

    sudo systemctl reload bind9

Then test DNS resolution from Kali:

    dig +short intranet.lab

---

## Troubleshooting

Check recent BIND9 errors:

    sudo journalctl -u bind9 -p err --since "1 hour ago" --no-pager

View recent BIND9 logs:

    sudo journalctl -u bind9 --since "1 hour ago" --no-pager

Check whether BIND9 is active:

    systemctl is-active bind9

Check whether DNS port 53 is listening:

    sudo ss -tulpn | grep ':53'

Test the zone from Kali:

    dig intranet.lab

Test the `www` record:

    dig www.intranet.lab

Test the web server after DNS resolution:

    curl http://intranet.lab

If DNS resolution fails, check the BIND9 configuration and zone file before troubleshooting Nginx. DNS and HTTP are separate services, so confirming each layer independently helps identify where the problem is.

---

## Validation

The DNS configuration was validated by:

- Confirming BIND9 was active.
- Confirming DNS port `53` was listening.
- Resolving `intranet.lab` from Kali.
- Confirming that `intranet.lab` resolved to `192.168.240.132`.
- Accessing the Nginx server using `http://intranet.lab`.
- Checking BIND9 logs for recent errors.
- Validating the BIND9 configuration and zone file.

---

## Relationship to Other Lab Services

BIND9 is used together with Nginx in the home lab.

The basic request flow is:

    Kali Linux
        |
        | DNS query for intranet.lab
        v
    BIND9 on Ubuntu
        |
        | Returns 192.168.240.132
        v
    Kali Linux
        |
        | HTTP request to intranet.lab
        v
    Nginx on Ubuntu

This demonstrates how DNS and web services work together in a small internal network.
