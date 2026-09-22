# PostgreSQL Configuration

PostgreSQL is used as the database server in my Ubuntu Server home lab.

I configured PostgreSQL to accept local connections and remote connections from my Kali Linux VM. Remote access is restricted to the Kali VM's lab IP address and requires password authentication using SCRAM-SHA-256.

## What I Configured

The PostgreSQL configuration involved:

- PostgreSQL 18
- Database: `labdb`
- Database user: `labuser`
- PostgreSQL port: `5432`
- Remote access from the Kali VM
- SCRAM-SHA-256 password authentication
- UFW firewall restriction for PostgreSQL
- Testing the connection from Kali

The public repository does not contain the database password or actual lab IP addresses.

---

## PostgreSQL Service

Check the PostgreSQL service:

    sudo systemctl status postgresql@18-main

Check whether it is active:

    systemctl is-active postgresql@18-main

Start PostgreSQL:

    sudo systemctl start postgresql@18-main

Stop PostgreSQL:

    sudo systemctl stop postgresql@18-main

Restart PostgreSQL:

    sudo systemctl restart postgresql@18-main

Reload PostgreSQL configuration:

    sudo systemctl reload postgresql@18-main

---

## Checking PostgreSQL Status

List PostgreSQL clusters:

    pg_lsclusters

This shows the PostgreSQL version, cluster name, port, status, and other information.

Check whether PostgreSQL is listening on port 5432:

    sudo ss -tulpn | grep ':5432'

---

## Accessing PostgreSQL Locally

Switch to the PostgreSQL administrative account:

    sudo -u postgres psql

List databases:

    \l

List database users/roles:

    \du

Connect to the lab database:

    \c labdb

Exit PostgreSQL:

    \q

---

## Database and User

The lab uses a database named:

    labdb

and a PostgreSQL user named:

    labuser

The user can be tested from the Ubuntu server with:

    psql -U labuser -d labdb

The command prompts for the database user's password when password authentication is required.

---

## Remote Connections

PostgreSQL normally restricts which network interfaces it listens on.

The configuration was changed so PostgreSQL listens on:

- `127.0.0.1` for local connections
- The Ubuntu Server's lab interface for connections from Kali

The PostgreSQL configuration file can be located with:

    sudo -u postgres psql -c "SHOW config_file;"

Check the configured listening addresses:

    sudo -u postgres psql -c "SHOW listen_addresses;"

Check the configured PostgreSQL port:

    sudo -u postgres psql -c "SHOW port;"

---

## pg_hba.conf

PostgreSQL uses `pg_hba.conf` to control client authentication.

Find the active file with:

    sudo -u postgres psql -c "SHOW hba_file;"

View the file:

    sudo nano /etc/postgresql/18/main/pg_hba.conf

The remote lab connection uses a rule equivalent to:

    host    labdb    labuser    192.168.240.133/32    scram-sha-256

The actual lab IP address is not included in this public repository.

### Authentication Rule

The rule specifies:

- `host` — TCP/IP connection
- `labdb` — only the lab database
- `labuser` — only the lab database account
- `192.168.240.133/32` — only the specific Kali VM
- `scram-sha-256` — password authentication using SCRAM-SHA-256

Using `/32` limits the rule to a single IPv4 address.

---

## Editing PostgreSQL Configuration

Edit the main PostgreSQL configuration:

    sudo nano /etc/postgresql/18/main/postgresql.conf

Edit the client authentication configuration:

    sudo nano /etc/postgresql/18/main/pg_hba.conf

After changing the configuration, check the PostgreSQL service:

    sudo systemctl status postgresql@18-main

If necessary, restart PostgreSQL:

    sudo systemctl restart postgresql@18-main

---

## Testing From Kali

From the Kali Linux VM, connect to the Ubuntu PostgreSQL server with:

    psql -h <192.168.240.132 -U labuser -d labdb

The password for `labuser` is required.

After connecting, verify the current user and database:

    SELECT current_user, current_database();

Expected result:

    current_user | current_database
    -------------+----------------
    labuser      | labdb

Exit:

    \q

The actual lab IP addresses are intentionally omitted from the public repository.

---

## Firewall Configuration

UFW was configured so PostgreSQL is not open to the entire network.

Check UFW status:

    sudo ufw status verbose

The PostgreSQL rule allows port 5432 only from the Kali VM's lab IP.

A rule equivalent to the lab configuration is:

    sudo ufw allow from <KALI_LAB_IP> to any port 5432 proto tcp

The actual IP address is not included in this repository.

Check the rules again:

    sudo ufw status numbered

---

## Checking PostgreSQL Logs

View recent PostgreSQL errors:

    sudo journalctl -u postgresql@18-main -p err --since "1 hour ago" --no-pager

View recent PostgreSQL service messages:

    sudo journalctl -u postgresql@18-main --since "1 hour ago" --no-pager

These commands were useful when troubleshooting PostgreSQL startup and configuration problems.

---

## Troubleshooting

### PostgreSQL Will Not Start

Check the service:

    sudo systemctl status postgresql@18-main

Check recent errors:

    sudo journalctl -u postgresql@18-main -p err --since "1 hour ago" --no-pager

Check the PostgreSQL configuration for syntax or configuration problems.

For configuration changes, inspect:

    sudo nano /etc/postgresql/18/main/postgresql.conf

and:

    sudo nano /etc/postgresql/18/main/pg_hba.conf

### Remote Connection Fails

From Kali, test the connection:

    psql -h 192.168.240.132 -U labuser -d labdb

On Ubuntu, verify PostgreSQL is listening:

    sudo ss -tulpn | grep ':5432'

Check the configured listening addresses:

    sudo -u postgres psql -c "SHOW listen_addresses;"

Check the authentication rules:

    sudo nano /etc/postgresql/18/main/pg_hba.conf

Check the firewall:

    sudo ufw status numbered

Check PostgreSQL logs:

    sudo journalctl -u postgresql@18-main -p err --since "1 hour ago" --no-pager

---

## Backup

A PostgreSQL custom-format backup of `labdb` was created for the home lab.

The backup was created with:

    sudo -u postgres pg_dump -Fc labdb | sudo tee /var/backup/home-lab/labdb-$(date +%Y-%m-%d).dump > /dev/null

List the contents of a backup:

    sudo pg_restore -l /var/backup/home-lab/labdb-$(date +%Y-%m-%d).dump

The backup directory is kept on the Ubuntu Server and is not committed to GitHub.

---

## Validation

The PostgreSQL configuration was validated by:

1. Confirming the PostgreSQL service was active.
2. Confirming port 5432 was listening on the Ubuntu lab interface.
3. Connecting from Kali using `psql`.
4. Running:

       SELECT current_user, current_database();

5. Confirming UFW restricted access to the Kali VM.
6. Checking PostgreSQL logs for recent errors.

The final home lab health check reports PostgreSQL as active and reports no recent PostgreSQL errors.
