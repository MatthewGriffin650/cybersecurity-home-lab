# UFW Firewall Configuration

## Overview

UFW (Uncomplicated Firewall) is the firewall used on the Ubuntu Server in this home lab.

I used UFW to control which network services can be reached from the lab network. The default configuration blocks incoming connections unless they are explicitly allowed.

The firewall was configured around the services running on the Ubuntu Server:

- SSH — port 22
- DNS — port 53
- HTTP — port 80
- PostgreSQL — port 5432

PostgreSQL is treated differently from the other services because access is restricted specifically to the Kali Linux lab machine.

---

## Check Firewall Status

Check the current firewall status:

    sudo ufw status

For more detail:

    sudo ufw status verbose

Display rules with rule numbers:

    sudo ufw status numbered

---

## Default Policies

The firewall was configured to deny incoming connections by default while allowing outgoing connections.

Set the default incoming policy:

    sudo ufw default deny incoming

Set the default outgoing policy:

    sudo ufw default allow outgoing

These defaults provide a baseline where new services are not automatically exposed through the firewall.

---

## SSH

SSH is used to remotely administer the Ubuntu Server.

Allow SSH:

    sudo ufw allow 22/tcp

Check that the rule was added:

    sudo ufw status

---

## HTTP

Nginx provides the web server for the lab's internal website.

Allow HTTP:

    sudo ufw allow 80/tcp

This allows HTTP traffic to reach the Nginx server.

---

## DNS

BIND9 provides DNS for the internal lab domain.

Allow DNS:

    sudo ufw allow 53

This allows DNS traffic to reach the BIND9 service.

---

## PostgreSQL

PostgreSQL uses TCP port `5432`.

Instead of allowing PostgreSQL connections from any host, the firewall rule restricts access to the Kali Linux lab machine.

Allow PostgreSQL from Kali:

    sudo ufw allow from 192.168.240.133 to any port 5432 proto tcp

The Kali Linux lab address is:

    192.168.240.133

The Ubuntu Server lab address is:

    192.168.240.132

This means a connection to PostgreSQL must pass both the UFW firewall restriction and PostgreSQL's own authentication rules.

---

## Enable UFW

After configuring the required rules, UFW can be enabled with:

    sudo ufw enable

Check the resulting configuration:

    sudo ufw status verbose

> Make sure SSH access has been configured before enabling UFW if administering the server remotely. Otherwise, it is possible to lock yourself out.

---

## Disable UFW

If the firewall needs to be temporarily disabled for troubleshooting:

    sudo ufw disable

Check its status:

    sudo ufw status

The firewall should normally remain enabled after troubleshooting is complete.

---

## Remove a Rule

List rules with their numbers:

    sudo ufw status numbered

A specific rule can then be removed using its rule number:

    sudo ufw delete <rule-number>

For example:

    sudo ufw delete 5

The rule number will depend on the current firewall configuration.

---

## Reset UFW

To completely remove the current UFW configuration:

    sudo ufw reset

This should only be used when intentionally rebuilding the firewall configuration because it removes the existing rules.

---

## Validation

After configuring UFW, I verified the firewall with:

    sudo ufw status verbose

I also verified that the expected services were listening:

    sudo ss -tulpn

The final configuration allowed the services required by the home lab while restricting PostgreSQL access to the Kali Linux machine.

---

## Troubleshooting

### Check whether UFW is active

    sudo ufw status verbose

### Check the current rules

    sudo ufw status numbered

### Check listening services

    sudo ss -tulpn

### Check whether a service is running

    sudo systemctl status <service>

### Test the web server from Kali

    curl http://intranet.lab

### Test PostgreSQL from Kali

    psql -h 192.168.240.132 -U labuser -d labdb

If a connection fails, check both the firewall and the service configuration. A firewall rule allowing a connection does not guarantee that the application itself is configured to accept it.

---

## Firewall Configuration Summary

| Service | Port | Firewall Access |
|---|---:|---|
| SSH | 22/TCP | Allowed |
| DNS | 53 | Allowed |
| HTTP | 80/TCP | Allowed |
| PostgreSQL | 5432/TCP | Kali only |

The firewall provides network-level access control, while individual services such as PostgreSQL provide their own authentication and authorization controls.
